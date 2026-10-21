/**
 * Appeal resolution (DSA art. 20(4)-(5), Terms 18.4 b-c).
 *
 *   b) "A person who did not make the original decision reviews them."
 *      -> a reviewer equal to the decision's decidedBy / confirmedBy is refused
 *         (permission-denied), and so is the appellant.
 *   c) "We reverse decisions that turn out to be wrong, and tell you the
 *      outcome and the reasons."
 *      -> overturned: every recorded effect of the decision is reversed
 *         (moderationEffects.ts reverseEffects: restore removed / quarantined
 *         content, lift suspension / ban incl. re-enabling Firebase Auth,
 *         revoke warning + strike, ...). For a REPORTER's appeal against a
 *         decision not to act, the original report is re-opened for a new
 *         review (by someone other than the first decider).
 *      -> partially_overturned: reversed, then a milder replacement measure
 *         (warning, or a suspension of N days) is applied and recorded.
 *      -> upheld: nothing changes.
 *      The outcome + written explanation is stored on the decision, the
 *      report_appeals doc and the appeal queue item, and sent to the user
 *      in-app and by email.
 *
 * Entry points:
 *   - callable resolveModerationAppeal (admin panel, MODERATION_ROLES)
 *   - takeModerationAction on an 'appeal' queue item: approve = overturn,
 *     dismiss = uphold, parameters.outcome = 'partially_overturned'
 *     (+ parameters.replacementAction / durationDays).
 *   - reverseDecisionOnReview: a moderator approving a held upload.
 */
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import '../shared/firebaseAdmin';
import { t as tr } from '../shared/i18n';
import { resolveLocale } from '../shared/i18n/recipientLocale';
import { monitored } from '../shared/monitoring';
import { syncLibraryAfterAppeal } from './mediaLibrary';
import { MODERATION_ROLES, requireAdmin } from '../shared/adminAuth';
import { authEmailOf, escapeHtml, sendEmailOnce } from '../emails/sendEmail';
import { detailsTable, emailFrame } from '../emails/emailFormat';
import {
  actionText, contentText, createModerationDecision, decisionNotificationData, MODERATION_DECISIONS,
} from './moderationDecisions';
import {
  applySuspension, DecisionEffect, parseEffects, recordStrike, recordWarning, reverseEffects, ReverseResult,
} from './moderationEffects';

const db = () => admin.firestore();
const HttpsError = functions.https.HttpsError;

export type AppealOutcome = 'upheld' | 'overturned' | 'partially_overturned';
export const APPEAL_OUTCOMES: AppealOutcome[] = ['upheld', 'overturned', 'partially_overturned'];
export type ReplacementAction = 'issueWarning' | 'suspendUser';

export interface ResolveAppealInput {
  appealId?: unknown;
  queueId?: unknown;
  outcome: unknown;
  explanation: unknown;
  replacementAction?: unknown;
  durationDays?: unknown;
  reviewerUid: string;
  nowMs?: number;
}

export interface ResolveAppealResult {
  appealId: string;
  decisionId: string | null;
  outcome: AppealOutcome;
  reversal: ReverseResult | null;
  reopenedQueueId: string | null;
  replacementDecisionId: string | null;
}

/** Pure validation (exported for tests). */
export function parseResolution(input: Pick<ResolveAppealInput, 'outcome' | 'explanation' | 'replacementAction' | 'durationDays'>): {
  outcome: AppealOutcome; explanation: string; replacement: { action: ReplacementAction; days: number } | null;
} {
  const outcome = input.outcome as AppealOutcome;
  if (!APPEAL_OUTCOMES.includes(outcome)) {
    throw new HttpsError('invalid-argument', 'outcome must be upheld, overturned or partially_overturned');
  }
  const explanation = typeof input.explanation === 'string' ? input.explanation.trim() : '';
  if (explanation.length < 5 || explanation.length > 2000) {
    throw new HttpsError('invalid-argument', 'explanation (the reasons told to the user) must be 5-2000 characters');
  }
  let replacement: { action: ReplacementAction; days: number } | null = null;
  if (outcome === 'partially_overturned') {
    const a = input.replacementAction;
    if (a !== 'issueWarning' && a !== 'suspendUser') {
      throw new HttpsError('invalid-argument', 'partially_overturned needs replacementAction issueWarning or suspendUser');
    }
    const days = Number(input.durationDays);
    if (a === 'suspendUser' && !(Number.isInteger(days) && days >= 1 && days <= 365)) {
      throw new HttpsError('invalid-argument', 'durationDays must be 1-365 for a replacement suspension');
    }
    replacement = { action: a, days: a === 'suspendUser' ? days : 0 };
  }
  return { outcome, explanation, replacement };
}

/** Terms 18.4 b: everyone who took part in the original decision. Pure. */
export function originalDeciders(decision: Record<string, any> | null | undefined, appeal: Record<string, any>, legacyReport?: Record<string, any> | null): Set<string> {
  const out = new Set<string>();
  for (const v of [decision?.decidedBy, decision?.confirmedBy, appeal.originalDecidedBy, legacyReport?.assignedModeratorId]) {
    if (typeof v === 'string' && v && v !== 'system') out.add(v);
  }
  return out;
}

const OUTCOME_KEY = {
  upheld: 'moderationAppealOutcomeUpheld',
  overturned: 'moderationAppealOutcomeOverturned',
  partially_overturned: 'moderationAppealOutcomePartial',
} as const;

async function findAppeal(input: ResolveAppealInput): Promise<string> {
  if (typeof input.appealId === 'string' && input.appealId && !input.appealId.includes('/')) return input.appealId;
  if (typeof input.queueId === 'string' && input.queueId && !input.queueId.includes('/')) {
    const q = (await db().collection('moderation_queue').doc(input.queueId).get()).data();
    if (q?.itemType === 'appeal' && typeof q.itemId === 'string') return q.itemId;
    throw new HttpsError('not-found', 'Appeal queue item not found');
  }
  throw new HttpsError('invalid-argument', 'appealId or queueId is required');
}

export async function resolveAppeal(input: ResolveAppealInput): Promise<ResolveAppealResult> {
  const { outcome, explanation, replacement } = parseResolution(input);
  const nowMs = input.nowMs ?? Date.now();
  const now = admin.firestore.Timestamp.fromMillis(nowMs);
  const appealId = await findAppeal(input);
  const appealRef = db().collection('report_appeals').doc(appealId);

  // Claim (one reviewer at a time) + independence check, atomically.
  const { appeal, decision } = await db().runTransaction(async (tx) => {
    const a = (await tx.get(appealRef)).data();
    if (!a) throw new HttpsError('not-found', 'Appeal not found');
    if (a.status !== 'pending') throw new HttpsError('failed-precondition', `Appeal is already ${a.status}`);
    const dRef = typeof a.decisionId === 'string' ? db().collection(MODERATION_DECISIONS).doc(a.decisionId) : null;
    const d = dRef ? (await tx.get(dRef)).data() ?? null : null;
    const legacy = !a.decisionId && typeof a.reportId === 'string'
      ? (await tx.get(db().collection('user_reports').doc(a.reportId))).data() ?? null : null;
    if (originalDeciders(d, a, legacy).has(input.reviewerUid)) {
      throw new HttpsError('permission-denied', 'A person who did not make the original decision must review this appeal (Terms 18.4 b)');
    }
    if (a.userId === input.reviewerUid) throw new HttpsError('permission-denied', 'You cannot review your own appeal');
    if (replacement && d?.role === 'reporter') {
      throw new HttpsError('invalid-argument', 'A reporter appeal can be upheld or overturned (re-review), not partially overturned');
    }
    tx.update(appealRef, { status: 'resolving', resolvingBy: input.reviewerUid, resolvingAt: now });
    return { appeal: a, decision: d };
  });

  const decisionId: string | null = typeof appeal.decisionId === 'string' ? appeal.decisionId : null;
  let reversal: ReverseResult | null = null;
  let reopenedQueueId: string | null = null;
  let replacementDecisionId: string | null = null;
  try {
    if (outcome !== 'upheld' && decision) {
      if (decision.role === 'reporter') {
        reopenedQueueId = await reopenReportForReReview(decision, appealId, nowMs);
      } else {
        reversal = await reverseEffects(parseEffects(decision.effects), decisionId!);
        if (replacement) {
          replacementDecisionId = await applyReplacement(decision, replacement, input.reviewerUid, explanation, nowMs);
        }
      }
    }
  } catch (e) {
    // Release the claim: the appeal stays open for another attempt.
    await appealRef.update({ status: 'pending', resolvingBy: null }).catch(() => undefined);
    throw e;
  }

  const record = {
    outcome,
    explanation,
    resolvedBy: input.reviewerUid,
    resolvedAt: now,
    reversal: reversal ?? null,
    reopenedQueueId,
    replacementDecisionId,
  };
  if (decisionId) {
    await db().collection(MODERATION_DECISIONS).doc(decisionId).update({
      appealStatus: outcome,
      appealOutcome: record,
    });
  }
  await appealRef.update({
    status: 'resolved',
    decision: outcome,
    reviewerNotes: explanation,
    reviewedAt: now,
    reviewedBy: input.reviewerUid,
    reversal: reversal ?? null,
    reopenedQueueId,
    replacementDecisionId,
    resolvingBy: null,
  });
  if (!decisionId && typeof appeal.reportId === 'string') {
    // Legacy report-based appeal: no recorded effects; the reviewer applies
    // any reversal by hand (unbanUserAccount / unsuspendUserAccount).
    await db().collection('user_reports').doc(appeal.reportId)
      .update({ status: outcome === 'upheld' ? 'resolved' : 'appeal_granted', appealOutcome: outcome })
      .catch(() => undefined);
  }
  const queueId = decisionId
    ? `appeal__${decisionId}`
    : (typeof appeal.queueId === 'string' ? appeal.queueId : await legacyAppealQueueId(appealId));
  if (queueId) {
    await db().collection('moderation_queue').doc(queueId).set({
      status: 'resolved',
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedBy: input.reviewerUid,
      action: `appeal_${outcome}`,
      moderatorNotes: explanation,
      statementOfReasons: { reasonCode: 'appeal', explanation, action: `appeal_${outcome}`, decidedBy: input.reviewerUid, decidedAt: now, automated: false },
    }, { merge: true });
  }
  // My pictures: an upheld appeal on a held image makes the hold final; an
  // overturned one was re-approved by restoreQuarantined (reverseEffects).
  try {
    await syncLibraryAfterAppeal(decision, outcome);
  } catch (e) {
    console.error(`[appeals] library sync for ${appealId} failed:`, e);
  }
  await db().collection('moderation_actions_log').add({
    moderatorId: input.reviewerUid,
    queueId: queueId ?? null,
    action: `appeal_${outcome}`,
    notes: explanation,
    statementOfReasons: { reasonCode: 'appeal', explanation },
    appealId,
    decisionId,
    reversal: reversal ?? null,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db().collection('admin_audit_log').add({
    adminId: input.reviewerUid,
    action: 'resolvedAppeal',
    targetType: 'report_appeal',
    targetId: appealId,
    details: { outcome, decisionId, userId: appeal.userId ?? null, reopenedQueueId, replacementDecisionId },
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    await notifyAppealOutcome({
      appealId,
      userId: appeal.userId,
      decision: decision ? { ...decision, appealStatus: outcome } : null,
      outcome,
      explanation,
      reporterReopened: !!reopenedQueueId,
    });
  } catch (e) {
    console.error(`[appeals] outcome notice for ${appealId} failed:`, e);
  }
  return { appealId, decisionId, outcome, reversal, reopenedQueueId, replacementDecisionId };
}

async function legacyAppealQueueId(appealId: string): Promise<string | null> {
  const s = await db().collection('moderation_queue').where('itemId', '==', appealId).limit(1).get();
  return s.empty ? null : s.docs[0].id;
}

/** Reporter appeal granted: the original report goes back into the queue. */
async function reopenReportForReReview(decision: Record<string, any>, appealId: string, nowMs: number): Promise<string | null> {
  const queueId = typeof decision.queueId === 'string' ? decision.queueId : null;
  if (!queueId) return null;
  const ref = db().collection('moderation_queue').doc(queueId);
  const q = (await ref.get()).data();
  if (!q) return null;
  const excluded = [q.resolvedBy, decision.decidedBy].filter((v): v is string => typeof v === 'string' && !!v && v !== 'unknown');
  await ref.update({
    status: 'pending',
    priority: q.priority === 'critical' ? 'critical' : 'high',
    assignedTo: null,
    reopenedByAppealId: appealId,
    reopenedAt: admin.firestore.Timestamp.fromMillis(nowMs),
    reopenCount: admin.firestore.FieldValue.increment(1),
    // The first decider may not take the new decision either.
    ...(excluded.length ? { excludedReviewers: admin.firestore.FieldValue.arrayUnion(...excluded) } : {}),
    previousResolution: { action: q.action ?? null, resolvedBy: q.resolvedBy ?? null, resolvedAt: q.resolvedAt ?? null },
  });
  return queueId;
}

async function applyReplacement(
  decision: Record<string, any>,
  r: { action: ReplacementAction; days: number },
  reviewerUid: string,
  explanation: string,
  nowMs: number,
): Promise<string> {
  const userId = decision.userId as string;
  const newId = `${decision.decisionId}__appeal`;
  const effects: DecisionEffect[] = [];
  if (r.action === 'suspendUser') {
    effects.push(await applySuspension({ userId, reason: explanation, days: r.days, decisionId: newId, by: reviewerUid, nowMs }));
    effects.push(await recordStrike({ userId, decisionId: newId, kind: 'suspension', nowMs }));
  } else {
    effects.push(await recordWarning({
      userId, reason: decision.reasonCode || 'other', description: explanation, severity: 'moderate', decisionId: newId, by: reviewerUid,
    }));
    effects.push(await recordStrike({ userId, decisionId: newId, kind: 'warning', nowMs }));
  }
  // The appeal decision itself is final internally (DSA art. 20); the user is
  // told through the appeal-outcome notice, with the art. 21 options.
  await createModerationDecision({
    decisionId: newId,
    queueId: decision.queueId ?? decision.decisionId,
    userId,
    action: r.action,
    reasonCode: decision.reasonCode ?? null,
    explanation,
    decidedBy: reviewerUid,
    contentRef: decision.contentRef ?? null,
    effects,
    appealable: false,
    inApp: false,
    email: false,
    extra: { replacesDecisionId: decision.decisionId, ...(r.action === 'suspendUser' ? { suspensionDays: r.days } : {}) },
    nowMs,
  });
  return newId;
}

/** In-app (opens the decision screen with the outcome) + email. */
export async function notifyAppealOutcome(p: {
  appealId: string;
  userId: unknown;
  decision: Record<string, any> | null;
  outcome: AppealOutcome;
  explanation: string;
  reporterReopened: boolean;
  notificationId?: string;
}): Promise<void> {
  const userId = typeof p.userId === 'string' ? p.userId : '';
  if (!userId) return;
  const locale = await resolveLocale(userId);
  const title = tr(locale, 'srvAppealOutcomeTitle');
  const body = tr(locale, 'srvAppealOutcomeBody');
  const base = p.decision
    ? decisionNotificationData(p.decision)
    : { action: 'moderation_decision', decisionId: `appeal_${p.appealId}`, moderationAction: '', reasonCode: 'other', explanation: '' };
  const data: Record<string, string> = {
    ...base,
    appealable: 'false',
    appealStatus: p.outcome,
    appealOutcome: p.reporterReopened ? 'report_reopened' : p.outcome,
    appealExplanation: p.explanation,
    appealId: p.appealId,
  };
  const notifId = p.notificationId ?? `appeal_outcome_${p.appealId}`;
  try {
    await db().collection('notifications').doc(notifId).create({
      userId,
      type: 'system',
      title,
      message: body,
      body,
      titleKey: 'srvAppealOutcomeTitle',
      bodyKey: 'srvAppealOutcomeBody',
      data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      actionUrl: null,
      imageUrl: null,
    });
  } catch (e: any) {
    if (!(e?.code === 6 || e?.code === 'already-exists')) throw e;
  }
  await sendEmailOnce(`appeal_outcome_${notifId}`, async () => {
    const to = await authEmailOf(userId);
    if (!to) return null;
    const outcomeLine = tr(locale, p.reporterReopened ? 'moderationAppealOutcomeReportReopened' : OUTCOME_KEY[p.outcome]);
    const rows: Array<[string, string | null]> = p.decision ? [
      [tr(locale, 'moderationDecisionActionLabel'), actionText(locale, p.decision.action)],
      [tr(locale, 'moderationDecisionContentLabel'), contentText(locale, p.decision.contentRef)],
    ] : [];
    rows.push([tr(locale, 'moderationAppealOutcomeLabel'), outcomeLine]);
    rows.push([tr(locale, 'moderationAppealReviewerNoteLabel'), p.explanation]);
    const inner = `<p>${escapeHtml(body)}</p>` + detailsTable(rows)
      + `<p style="color:#555;font-size:13px">${escapeHtml(tr(locale, 'moderationDecisionOtherOptions'))}</p>`;
    return { to: [to], subject: tr(locale, 'srvAppealOutcomeEmailSubject'), html: emailFrame(inner), replyTo: 'safety@greengochat.com' };
  }, { kind: 'appeal_outcome', appealId: p.appealId });
}

/**
 * A moderator reverses a decision outside an appeal (e.g. approves an upload
 * the Vision screen held back). Resolves a pending appeal of it as overturned;
 * otherwise reverses the effects and tells the user.
 */
export async function reverseDecisionOnReview(decisionId: string, reviewerUid: string, explanation: string): Promise<ReverseResult | null> {
  const ref = db().collection(MODERATION_DECISIONS).doc(decisionId);
  const d = (await ref.get()).data();
  if (!d) return null;
  if (d.appealStatus === 'pending' && typeof d.appealId === 'string') {
    const r = await resolveAppeal({ appealId: d.appealId, outcome: 'overturned', explanation, reviewerUid });
    return r.reversal;
  }
  if (d.appealStatus && d.appealStatus !== 'pending') return null; // already decided
  const reversal = await reverseEffects(parseEffects(d.effects), decisionId);
  await ref.update({
    appealStatus: 'overturned',
    appealable: false,
    appealOutcome: {
      outcome: 'overturned', explanation, resolvedBy: reviewerUid,
      resolvedAt: admin.firestore.Timestamp.now(), reversal, onReview: true,
    },
  });
  await notifyAppealOutcome({
    appealId: `review_${decisionId}`,
    userId: d.userId,
    decision: { ...d, appealStatus: 'overturned' },
    outcome: 'overturned',
    explanation,
    reporterReopened: false,
    notificationId: `decision_reversed_${decisionId}`,
  });
  return reversal;
}

/**
 * resolveModerationAppeal({ appealId | queueId, outcome, explanation,
 *   replacementAction?, durationDays? }) — admin panel (MODERATION_ROLES).
 */
export const resolveModerationAppeal = functions
  .runWith({ memory: '512MB', timeoutSeconds: 120 })
  .https.onCall(monitored('resolveModerationAppeal', async (data, context) => {
    await requireAdmin(context.auth as any, MODERATION_ROLES);
    const d = data || {};
    return resolveAppeal({
      appealId: d.appealId,
      queueId: d.queueId,
      outcome: d.outcome,
      explanation: d.explanation,
      replacementAction: d.replacementAction,
      durationDays: d.durationDays,
      reviewerUid: context.auth!.uid,
    });
  }));
