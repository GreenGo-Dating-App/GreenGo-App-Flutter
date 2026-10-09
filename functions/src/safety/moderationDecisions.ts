/**
 * DSA art. 17 (statement of reasons) + art. 20 (internal complaint handling),
 * plan P2-8c.
 *
 * When a moderator takes an action that affects a user (takeModerationAction:
 * content removed, warning, suspension, ban, visibility restriction,
 * verification required), the affected user gets:
 *   - a server-only record  moderation_decisions/{queueId}
 *       { userId, queueId, action, reasonCode, explanation, decidedAt,
 *         automated:false, appealable, appealDeadline, appealStatus }
 *   - one in-app notification (type 'system', so every app version renders
 *     it; push via the parity trigger) carrying the statement of reasons in
 *     `data` and the decisionId the app uses to appeal (submitAppeal).
 *
 * Appeals (submitAppealForDecision): the user's own decision, once, within
 * APPEAL_WINDOW_DAYS (DSA: at least six months). Creates report_appeals/{id}
 * and a moderation_queue item 'appeal' for a human reviewer.
 */
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import '../shared/firebaseAdmin';
import { t as tr } from '../shared/i18n';
import { resolveLocale } from '../shared/i18n/recipientLocale';

const db = () => admin.firestore();

export const MODERATION_DECISIONS = 'moderation_decisions';
/** DSA art. 20(1): complaints possible for at least six months. */
export const APPEAL_WINDOW_DAYS = 183;
export const APPEAL_MIN_CHARS = 10;
export const APPEAL_MAX_CHARS = 2000;

/** Actions that restrict the user or their content (art. 17(1)). */
export const USER_AFFECTING_ACTIONS = new Set([
  'removeContent', 'issueWarning', 'suspendUser', 'banUser', 'shadowBan', 'requireVerification',
]);

export function decisionNotificationId(queueId: string): string {
  return `moderation_decision_${queueId}`;
}

function isAlreadyExists(e: unknown): boolean {
  const code = (e as { code?: unknown })?.code;
  return code === 6 || code === 'already-exists' || code === 'ALREADY_EXISTS';
}

/**
 * Records the decision and notifies the affected user. Idempotent (doc ids
 * derive from the queue id). Never throws for a missing user.
 */
export async function notifyAffectedUserOfDecision(p: {
  queueId: string;
  userId: string | null | undefined;
  action: string;
  reasonCode: string | null;
  explanation: string | null;
  moderatorId: string;
  nowMs?: number;
}): Promise<boolean> {
  if (!USER_AFFECTING_ACTIONS.has(p.action)) return false;
  const userId = typeof p.userId === 'string' ? p.userId : '';
  if (!userId) return false;
  const nowMs = p.nowMs ?? Date.now();
  const deadline = admin.firestore.Timestamp.fromMillis(nowMs + APPEAL_WINDOW_DAYS * 86_400_000);
  const reasonCode = p.reasonCode || 'other';
  const explanation = (p.explanation || '').slice(0, 2000);

  const decisionRef = db().collection(MODERATION_DECISIONS).doc(p.queueId);
  try {
    await decisionRef.create({
      decisionId: p.queueId,
      queueId: p.queueId,
      userId,
      action: p.action,
      reasonCode,
      explanation,
      decidedBy: p.moderatorId,
      decidedAt: admin.firestore.Timestamp.fromMillis(nowMs),
      automated: false,
      appealable: true,
      appealDeadline: deadline,
      appealStatus: null,
    });
  } catch (e) {
    if (isAlreadyExists(e)) return false;
    throw e;
  }

  // Stored in the user's language (as before) for app versions without key
  // support, plus titleKey/bodyKey so newer apps follow the UI language.
  const locale = await resolveLocale(userId);
  const t = {
    title: tr(locale, 'srvModerationDecisionTitle'),
    body: tr(locale, 'srvModerationDecisionBody'),
  };
  try {
    await db().collection('notifications').doc(decisionNotificationId(p.queueId)).create({
      userId,
      type: 'system',
      title: t.title,
      message: t.body,
      body: t.body,
      titleKey: 'srvModerationDecisionTitle',
      bodyKey: 'srvModerationDecisionBody',
      data: {
        action: 'moderation_decision',
        decisionId: p.queueId,
        moderationAction: p.action,
        reasonCode,
        explanation,
        appealable: 'true',
        appealDeadline: deadline.toDate().toISOString(),
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      actionUrl: null,
      imageUrl: null,
    });
  } catch (e) {
    if (!isAlreadyExists(e)) throw e;
  }
  return true;
}

/**
 * submitAppeal({ decisionId, appealReason }) — the DSA art. 20 path. Throws
 * HttpsError (v1) with stable codes the app maps to messages.
 */
export async function submitAppealForDecision(
  uid: string,
  data: { decisionId?: unknown; appealReason?: unknown },
  nowMs: number = Date.now(),
): Promise<{ appealId: string; status: 'submitted' }> {
  const HttpsError = functions.https.HttpsError;
  const decisionId = typeof data.decisionId === 'string' ? data.decisionId.trim() : '';
  if (!decisionId || decisionId.length > 1500 || decisionId.includes('/')) {
    throw new HttpsError('invalid-argument', 'decisionId is required');
  }
  const reason = typeof data.appealReason === 'string' ? data.appealReason.trim() : '';
  if (reason.length < APPEAL_MIN_CHARS || reason.length > APPEAL_MAX_CHARS) {
    throw new HttpsError('invalid-argument', `appealReason must be ${APPEAL_MIN_CHARS}-${APPEAL_MAX_CHARS} characters`);
  }

  const decisionRef = db().collection(MODERATION_DECISIONS).doc(decisionId);
  const appealRef = db().collection('report_appeals').doc();
  const queueRef = db().collection('moderation_queue').doc(`appeal__${decisionId}`);

  await db().runTransaction(async (tx) => {
    const snap = await tx.get(decisionRef);
    const d = snap.data();
    if (!snap.exists || !d) throw new HttpsError('not-found', 'Decision not found');
    if (d.userId !== uid) throw new HttpsError('permission-denied', 'You can only appeal decisions about your own account');
    if (d.appealStatus) throw new HttpsError('already-exists', 'This decision was already appealed');
    const deadline = d.appealDeadline instanceof admin.firestore.Timestamp ? d.appealDeadline.toMillis() : 0;
    if (d.appealable !== true || nowMs > deadline) {
      throw new HttpsError('failed-precondition', 'The appeal window for this decision has closed');
    }
    const now = admin.firestore.Timestamp.fromMillis(nowMs);
    tx.set(appealRef, {
      appealId: appealRef.id,
      decisionId,
      queueId: d.queueId ?? decisionId,
      reportId: null,
      userId: uid,
      appealReason: reason,
      evidenceUrls: [],
      action: d.action ?? null,
      reasonCode: d.reasonCode ?? null,
      createdAt: now,
      status: 'pending',
      reviewerNotes: null,
      reviewedAt: null,
      decision: null,
    });
    tx.set(queueRef, {
      queueId: queueRef.id,
      itemType: 'appeal',
      itemId: appealRef.id,
      userId: uid,
      priority: 'medium',
      status: 'pending',
      addedAt: now,
      createdAt: now,
      assignedTo: null,
      relatedReportIds: [],
      metadata: { decisionId, originalQueueId: d.queueId ?? decisionId, action: d.action ?? null, reasonCode: d.reasonCode ?? null },
      content: { text: reason.slice(0, 2000), explanation: d.explanation ?? null },
      reporterId: 'system',
    });
    tx.update(decisionRef, { appealStatus: 'pending', appealId: appealRef.id, appealedAt: now });
  });
  return { appealId: appealRef.id, status: 'submitted' };
}
