/**
 * Moderation Queue Cloud Functions
 * Points 246-250: Content moderation queue management
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { t } from '../shared/i18n';
import { monitored } from '../shared/monitoring';
import { MODERATION_ROLES, requireAdmin } from '../shared/adminAuth';
import {
  APPEAL_WINDOW_DAYS, automationFor, contentReferenceFor, MODERATION_DECISIONS, notifyAffectedUserOfDecision,
} from '../safety/moderationDecisions';
import {
  applyBan, applySuspension, backupMessage, DecisionEffect, recordStrike, recordWarning, restoreQuarantined,
} from '../safety/moderationEffects';
import { escalateIfRepeatOffender } from '../safety/repeatOffenders';
import { originalDeciders, resolveAppeal, reverseDecisionOnReview } from '../safety/appealResolution';
import { clearReporterReview, suspendReporting, SUSPEND_DAYS as REPORTER_SUSPEND_DAYS } from '../safety/reporterStanding';

const firestore = admin.firestore();

/**
 * Verify Moderator Permission Helper
 *
 * P1-6: the admin panel roles (admin_users / `adminRole` claim) are the only
 * source of truth. The legacy `moderator` / `admin` boolean claims checked here
 * before were set by nothing, so panel moderators could not use these
 * callables at all (and fell back to direct writes that the rules deny).
 */
async function verifyModeratorPermission(
  context: functions.https.CallableContext
): Promise<void> {
  await requireAdmin(context.auth as any, MODERATION_ROLES);
}

/**
 * Statement of reasons (DSA art. 17). The moderator picks a code and writes a
 * short explanation; both are stored on the queue item, the action log and the
 * related reports. Optional on the wire for backward compatibility; the admin
 * panel always sends them.
 */
export const STATEMENT_REASON_CODES = [
  'csae', 'underage', 'sexual_content', 'inappropriate', 'threats', 'violence',
  'harassment', 'hate', 'spam', 'scam', 'impersonation', 'privacy', 'misleading',
  'no_show', 'off_platform_payment', 'other', 'no_violation',
  // Terms 18.6: repeat offenders / abusive reporters.
  'repeat_violations', 'unfounded_reports',
] as const;
export type StatementReasonCode = typeof STATEMENT_REASON_CODES[number];
const MAX_EXPLANATION = 2000;

export interface StatementOfReasons {
  reasonCode: StatementReasonCode;
  explanation: string;
}

/** Validates the optional statement of reasons; throws invalid-argument. */
export function parseStatementOfReasons(data: any): StatementOfReasons | null {
  const reasonCode = data?.reasonCode ?? data?.statementOfReasons?.reasonCode;
  const explanation = data?.explanation ?? data?.statementOfReasons?.explanation;
  if (reasonCode === undefined && explanation === undefined) return null;
  if (typeof reasonCode !== 'string' || !(STATEMENT_REASON_CODES as readonly string[]).includes(reasonCode)) {
    throw new functions.https.HttpsError('invalid-argument', 'reasonCode is not a known statement-of-reasons code');
  }
  if (typeof explanation !== 'string' || explanation.trim().length < 5) {
    throw new functions.https.HttpsError('invalid-argument', 'explanation must be at least 5 characters');
  }
  if (explanation.length > MAX_EXPLANATION) {
    throw new functions.https.HttpsError('invalid-argument', `explanation must be at most ${MAX_EXPLANATION} characters`);
  }
  return { reasonCode: reasonCode as StatementReasonCode, explanation: explanation.trim() };
}

/**
 * Log Moderation Action Helper
 */
async function logModerationAction(
  moderatorId: string,
  queueId: string,
  action: string,
  notes: string | null,
  statementOfReasons: StatementOfReasons | null = null
): Promise<void> {
  await firestore.collection('moderation_actions_log').add({
    moderatorId,
    queueId,
    action,
    notes,
    statementOfReasons,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Collection holding a queue item's related reports. Items created by the report
 * pipeline (safety/reportPipeline.ts) carry `source.collection`
 * (user_reports | message_reports | reports); legacy items are user_reports.
 */
function reportCollectionFor(queueData: any): string {
  const c = queueData?.source?.collection;
  return c === 'message_reports' || c === 'reports' || c === 'user_reports' ? c : 'user_reports';
}

/** Best-effort update of every related report (a missing doc must not abort the action). */
async function updateRelatedReports(queueData: any, patch: Record<string, unknown>): Promise<void> {
  const col = reportCollectionFor(queueData);
  for (const reportId of queueData.relatedReportIds || []) {
    try {
      await firestore.collection(col).doc(reportId).update(patch);
    } catch (err: any) {
      console.error(`Could not update ${col}/${reportId}:`, err?.message || err);
    }
  }
}

/**
 * Get Moderation Queue
 * Point 246: Fetch pending reports for review
 */
export const getModerationQueue = functions
  .runWith({ memory: '512MB' })
  .https.onCall(monitored("getModerationQueue", async (data, context) => {
  await verifyModeratorPermission(context);

  const {
    status = 'pending',
    priority = null,
    limit = 50,
    offset = 0,
    assignedToMe = false,
  } = data;

  try {
    let query: any = firestore.collection('moderation_queue');

    // Filter by status
    if (status) {
      query = query.where('status', '==', status);
    }

    // Filter by priority
    if (priority) {
      query = query.where('priority', '==', priority);
    }

    // Filter by assignment
    if (assignedToMe) {
      query = query.where('assignedTo', '==', context.auth!.uid);
    }

    // Order by priority (critical first) then by time
    query = query.orderBy('addedAt', 'asc');

    const snapshot = await query.limit(limit).offset(offset).get();

    const queueItems = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        queueId: data.queueId,
        itemType: data.itemType,
        itemId: data.itemId,
        userId: data.userId,
        priority: data.priority,
        addedAt: data.addedAt,
        assignedTo: data.assignedTo || null,
        assignedAt: data.assignedAt || null,
        relatedReportIds: data.relatedReportIds || [],
        metadata: data.metadata || {},
        status: data.status,
      };
    });

    // Sort by priority level
    queueItems.sort((a, b) => {
      const priorityOrder: any = { critical: 0, high: 1, medium: 2, low: 3 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });

    return {
      queueItems,
      total: queueItems.length,
    };
  } catch (error: any) {
    console.error('Error getting moderation queue:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}));

/**
 * Get Moderation Review Item
 * Point 247: Detailed review interface with context
 */
export const getModerationReviewItem = functions.runWith({ memory: '512MB' }).https.onCall(monitored("getModerationReviewItem", async (data, context) => {
  await verifyModeratorPermission(context);

  const { queueId } = data;

  try {
    const queueDoc = await firestore.collection('moderation_queue').doc(queueId).get();

    if (!queueDoc.exists) {
      throw new Error('Queue item not found');
    }

    const queueData = queueDoc.data()!;

    // Get the actual content based on item type
    let content: any = null;
    let appealContext: any = null;
    if (queueData.itemType === 'userReport') {
      const reportDoc = await firestore.collection('user_reports').doc(queueData.itemId).get();
      content = reportDoc.data();
    } else if (queueData.itemType === 'flaggedPhoto') {
      const photoDoc = await firestore.collection('flagged_photos').doc(queueData.itemId).get();
      content = photoDoc.data();
    } else if (queueData.itemType === 'flaggedMessage') {
      const messageDoc = await firestore.collection('messages').doc(queueData.itemId).get();
      content = messageDoc.data();
    } else if (queueData.itemType === 'appeal') {
      // DSA art. 20: the appeal, the original decision and who may NOT resolve it.
      const a = (await firestore.collection('report_appeals').doc(queueData.itemId).get()).data() || {};
      const d = typeof a.decisionId === 'string'
        ? (await firestore.collection(MODERATION_DECISIONS).doc(a.decisionId).get()).data() || null
        : null;
      const excluded = [...originalDeciders(d, a)];
      appealContext = {
        appealId: queueData.itemId,
        role: a.role ?? d?.role ?? 'affected',
        channel: a.channel ?? 'app',
        status: a.status ?? null,
        appealReason: a.appealReason ?? null,
        originalDecision: d ? {
          decisionId: d.decisionId, action: d.action, reasonCode: d.reasonCode, explanation: d.explanation,
          decidedBy: d.decidedBy, decidedAt: d.decidedAt, contentRef: d.contentRef ?? null,
          automated: d.automated === true, automatedDetection: d.automatedDetection ?? null,
          effects: d.effects ?? [], queueId: d.queueId ?? null,
        } : null,
        excludedReviewers: excluded,
        canResolve: !excluded.includes(context.auth!.uid) && a.userId !== context.auth!.uid,
        outcomes: ['upheld', 'overturned', 'partially_overturned'],
      };
      content = { ...a, text: a.appealReason ?? null };
    } else if (queueData.itemType === 'quarantinedImage' || queueData.type === 'image') {
      content = {
        objectPath: queueData.objectPath ?? null,
        quarantinePath: queueData.quarantinePath ?? null,
        reasons: queueData.reasons ?? [],
        safeSearch: queueData.safeSearch ?? null,
        labels: queueData.labels ?? [],
        visibility: queueData.visibility ?? null,
      };
    } else if (queueData.source?.collection) {
      // Report-pipeline item from message_reports / reports.
      const reportDoc = await firestore
        .collection(reportCollectionFor(queueData))
        .doc(queueData.itemId)
        .get();
      content = reportDoc.data();
    }

    // Get user context
    // A report may not name a user (e.g. an event with no organizer id).
    const userDoc = queueData.userId
      ? await firestore.collection('users').doc(queueData.userId).get()
      : null;
    const userData: any = userDoc?.data() || {};

    // Get report count for this user
    const reportCountSnapshot = await firestore
      .collection('user_reports')
      .where('reportedUserId', '==', queueData.userId)
      .count()
      .get();

    // Get warning count
    const warningCountSnapshot = await firestore
      .collection('user_warnings')
      .where('userId', '==', queueData.userId)
      .count()
      .get();

    const userContext = {
      userId: queueData.userId,
      displayName: userData.displayName,
      age: userData.age,
      photoUrl: userData.photos?.[0] || null,
      accountCreatedAt: userData.createdAt,
      reportCount: reportCountSnapshot.data().count,
      warningCount: warningCountSnapshot.data().count,
      suspensionCount: 0,
      isVerified: userData.isPhotoVerified || false,
      trustScore: userData.trustScore || 0,
      accountStatus: userData.accountStatus,
    };

    // Get related reports
    const relatedReports = [];
    for (const reportId of queueData.relatedReportIds || []) {
      const reportDoc = await firestore.collection(reportCollectionFor(queueData)).doc(reportId).get();
      if (reportDoc.exists) {
        const reportData = reportDoc.data()!;
        relatedReports.push({
          reportId,
          reporterId: reportData.reporterId,
          category: reportData.category ?? queueData.category ?? null,
          description: reportData.description ?? reportData.reason ?? null,
          createdAt: reportData.createdAt,
          screenshotUrls: reportData.screenshotUrls || [],
        });
      }
    }

    // Get moderation history
    const pastActionsSnapshot = await firestore
      .collection('moderation_actions_log')
      .where('queueId', '==', queueId)
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const pastActions = pastActionsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        actionType: data.action,
        reason: data.notes || '',
        statementOfReasons: data.statementOfReasons || null,
        moderatorId: data.moderatorId,
        actionAt: data.timestamp,
      };
    });

    const history = {
      pastActions,
      totalWarnings: warningCountSnapshot.data().count,
      totalSuspensions: 0,
      totalBans: 0,
      lastActionAt: pastActions.length > 0 ? pastActions[0].actionAt : null,
    };

    // Generate AI suggested actions
    const suggestedActions = generateSuggestedActions(
      queueData,
      userContext,
      relatedReports
    );

    return {
      queueId,
      itemType: queueData.itemType,
      content: {
        itemId: queueData.itemId,
        text: content?.description || content?.text || content?.messageContent || queueData.content?.text || null,
        photoUrls: content?.screenshotUrls || content?.photoUrls || [],
        additionalData: content || {},
        createdAt: content?.createdAt || queueData.addedAt,
      },
      // Report-pipeline fields (P1-12): what was reported, why, and the SLA.
      source: queueData.source || null,
      reportType: queueData.reportType || null,
      contentRef: queueData.contentRef || null,
      reason: queueData.reason || null,
      reasonCode: queueData.reasonCode || queueData.metadata?.reasonCode || null,
      priorityLevel: queueData.priorityLevel || null,
      slaDueAt: queueData.slaDueAt || null,
      reporterId: queueData.reporterId || queueData.metadata?.reporterId || null,
      queueContent: queueData.content || null,
      status: queueData.status || null,
      assignedTo: queueData.assignedTo || null,
      statementOfReasons: queueData.statementOfReasons || null,
      appealContext,
      excludedReviewers: queueData.excludedReviewers || [],
      userContext,
      relatedReports,
      history,
      suggestedActions,
      addedAt: queueData.addedAt,
      priority: queueData.priority,
    };
  } catch (error: any) {
    console.error('Error getting moderation review item:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}));

/**
 * Generate AI Suggested Actions
 */
function generateSuggestedActions(
  queueData: any,
  userContext: any,
  relatedReports: any[]
): any[] {
  const suggestions = [];

  // High report count → suggest ban
  if (userContext.reportCount >= 10) {
    suggestions.push({
      actionType: 'banUser',
      confidence: 0.9,
      reasoning: `User has ${userContext.reportCount} reports, indicating pattern of violations`,
      parameters: { permanent: true },
    });
  }

  // Multiple warnings → suggest suspension
  if (userContext.warningCount >= 3) {
    suggestions.push({
      actionType: 'suspendUser',
      confidence: 0.8,
      reasoning: `User has ${userContext.warningCount} warnings, escalation needed`,
      parameters: { durationDays: 7 },
    });
  }

  // Low trust score → suggest shadow ban
  if (userContext.trustScore < 30) {
    suggestions.push({
      actionType: 'shadowBan',
      confidence: 0.7,
      reasoning: `Low trust score (${userContext.trustScore}) suggests problematic behavior`,
      parameters: { visibilityReduction: 0.9 },
    });
  }

  // First offense → suggest warning
  if (userContext.reportCount === 1 && userContext.warningCount === 0) {
    suggestions.push({
      actionType: 'issueWarning',
      confidence: 0.85,
      reasoning: 'First offense, warning appropriate for education',
      parameters: { severity: 'minor' },
    });
  }

  // Critical priority → suggest immediate action
  if (queueData.priority === 'critical') {
    suggestions.push({
      actionType: 'removeContent',
      confidence: 0.95,
      reasoning: 'Critical priority violation requires immediate content removal',
      parameters: {},
    });
  }

  // If no strong suggestion, offer dismiss option
  if (suggestions.length === 0) {
    suggestions.push({
      actionType: 'dismiss',
      confidence: 0.6,
      reasoning: 'Insufficient evidence of policy violation',
      parameters: {},
    });
  }

  return suggestions;
}

/**
 * Assign Moderation Item
 * Assign queue item to moderator
 */
export const assignModerationItem = functions
  .runWith({ memory: '512MB' })
  .https.onCall(monitored("assignModerationItem", async (data, context) => {
  await verifyModeratorPermission(context);

  const { queueId } = data;
  const moderatorId = context.auth!.uid;

  try {
    await firestore.collection('moderation_queue').doc(queueId).update({
      assignedTo: moderatorId,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'assigned',
    });

    return { success: true };
  } catch (error: any) {
    console.error('Error assigning moderation item:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}));

/**
 * Take Moderation Action
 * Point 248: Execute moderation decision
 *
 * Every action that affects a user records a decision with its effects
 * (safety/moderationDecisions.ts) so the user gets the statement of reasons
 * (in-app + email) and an appeal that can reverse it.
 *
 * Special item types:
 *   - 'appeal': approve = overturn, dismiss = uphold
 *     (parameters.outcome 'partially_overturned' + replacementAction /
 *     durationDays); resolved by safety/appealResolution.ts, which refuses the
 *     moderator who took the original decision (Terms 18.4 b).
 *   - 'quarantinedImage' (Vision screen): approve restores the upload to its
 *     original path; removeContent confirms the hold.
 *   - 'reporterAbuse': suspendReporting (parameters.durationDays, default 30)
 *     or dismiss (Terms 18.6 / DSA art. 23).
 */
export const takeModerationAction = functions.runWith({ memory: '512MB' }).https.onCall(monitored("takeModerationAction", async (data, context) => {
  await verifyModeratorPermission(context);

  const { queueId, action, notes = null, parameters = {} } = data || {};
  const moderatorId = context.auth!.uid;
  if (typeof queueId !== 'string' || !queueId) {
    throw new functions.https.HttpsError('invalid-argument', 'queueId is required');
  }
  if (typeof action !== 'string' || !MODERATION_ACTIONS.has(action)) {
    throw new functions.https.HttpsError('invalid-argument', `Unknown action: ${action}`);
  }
  const statementOfReasons = parseStatementOfReasons(data);

  const queueDoc = await firestore.collection('moderation_queue').doc(queueId).get();
  if (!queueDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Queue item not found');
  }
  const queueData: any = { ...queueDoc.data()!, queueId: queueDoc.data()!.queueId ?? queueId };
  if (FINAL_QUEUE_STATUSES.has(queueData.status)) {
    throw new functions.https.HttpsError('failed-precondition', `Queue item is already ${queueData.status}`);
  }

  // Appeals: resolved by a person who did not take the original decision.
  if (queueData.itemType === 'appeal') {
    if (action !== 'approve' && action !== 'dismiss') {
      throw new functions.https.HttpsError('failed-precondition',
        'Appeal items: approve = overturn the decision, dismiss = uphold it');
    }
    const outcome = action === 'dismiss'
      ? 'upheld'
      : (parameters?.outcome === 'partially_overturned' ? 'partially_overturned' : 'overturned');
    const r = await resolveAppeal({
      queueId,
      outcome,
      explanation: statementOfReasons?.explanation ?? notes,
      replacementAction: parameters?.replacementAction,
      durationDays: parameters?.durationDays,
      reviewerUid: moderatorId,
    });
    return { queueId, action, moderatorId, notes, statementOfReasons, appeal: r, success: true, errorMessage: null };
  }

  // A report re-opened by a reporter's appeal: not by the first decider.
  if (Array.isArray(queueData.excludedReviewers) && queueData.excludedReviewers.includes(moderatorId)) {
    throw new functions.https.HttpsError('permission-denied',
      'This report was re-opened on appeal: a person who did not take the first decision must review it');
  }
  if (action === 'suspendReporting' && queueData.itemType !== 'reporterAbuse') {
    throw new functions.https.HttpsError('failed-precondition', 'suspendReporting applies to reporterAbuse items only');
  }

  // Execute the action FIRST. If it fails the item stays open (it used to be
  // marked resolved anyway, so a failed ban looked like a handled report).
  const reasonText = statementOfReasons?.explanation ?? notes;
  const effects: DecisionEffect[] = [];
  const contentRef = contentReferenceFor(queueData);
  const automated = automationFor(queueData);
  let escalation: { escalated: boolean; days?: number } | null = null;
  let reversal: unknown = null;
  const decisionAction: string = action;
  let decisionReason: string | null = statementOfReasons?.reasonCode ?? queueData.reasonCode ?? null;
  try {
    switch (action) {
      case 'approve':
        reversal = await approveContent(queueData, moderatorId, reasonText);
        break;
      case 'dismiss':
        await dismissReport(queueData);
        break;
      case 'removeContent':
        effects.push(...await removeContent(queueData, moderatorId, statementOfReasons));
        break;
      case 'issueWarning':
        effects.push(...await issueWarningToUser(targetUserId(queueData), queueData, reasonText, queueId, moderatorId));
        break;
      case 'suspendUser': {
        const durationDays = Number(parameters.durationDays) > 0 ? Number(parameters.durationDays) : 7;
        const uid = targetUserId(queueData);
        effects.push(await applySuspension({ userId: uid, reason: reasonText || 'Policy violation', days: durationDays, decisionId: queueId, by: moderatorId }));
        effects.push(await recordStrike({ userId: uid, decisionId: queueId, kind: 'suspension' }));
        break;
      }
      case 'banUser': {
        const uid = targetUserId(queueData);
        effects.push(await applyBan({ userId: uid, reason: reasonText || 'Severe policy violation', decisionId: queueId, by: moderatorId }));
        effects.push(await recordStrike({ userId: uid, decisionId: queueId, kind: 'ban' }));
        break;
      }
      case 'shadowBan':
        effects.push(await shadowBanUser(targetUserId(queueData)));
        break;
      case 'requireVerification':
        effects.push(await requireVerification(targetUserId(queueData)));
        break;
      case 'suspendReporting': {
        const days = Number(parameters.durationDays) > 0 ? Math.min(Number(parameters.durationDays), 180) : REPORTER_SUSPEND_DAYS;
        effects.push(...await suspendReporting({
          uid: targetUserId(queueData), days, decisionId: queueId, moderatorId, explanation: reasonText,
        }));
        decisionReason = 'unfounded_reports';
        break;
      }
    }
  } catch (err: any) {
    if (err instanceof functions.https.HttpsError) throw err;
    console.error(`takeModerationAction ${action} on ${queueId} failed:`, err);
    throw new functions.https.HttpsError('aborted', `Action ${action} failed: ${err?.message || err}`);
  }

  try {
    const sor = statementOfReasons
      ? {
          ...statementOfReasons,
          action,
          decidedBy: moderatorId,
          decidedAt: admin.firestore.FieldValue.serverTimestamp(),
          automated: automated.detection !== null,
        }
      : null;

    // Update queue item status
    await firestore.collection('moderation_queue').doc(queueId).update({
      status: 'resolved',
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedBy: moderatorId,
      action,
      moderatorNotes: notes ?? statementOfReasons?.explanation ?? null,
      ...(sor ? { statementOfReasons: sor } : {}),
    });

    // Update all related reports
    await updateRelatedReports(queueData, {
      status: 'resolved',
      action,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderatorNotes: notes,
      ...(statementOfReasons ? { resolutionReasonCode: statementOfReasons.reasonCode } : {}),
    });

    // Log moderation action
    await logModerationAction(moderatorId, queueId, action, notes, statementOfReasons);

    // Log to admin audit
    await firestore.collection('admin_audit_log').add({
      adminId: moderatorId,
      action: 'reviewedReport',
      targetType: 'moderation_queue',
      targetId: queueId,
      details: { action, notes, userId: queueData.userId, statementOfReasons },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // DSA art. 17/20 (Terms 18.3/18.4): statement of reasons (in-app + email)
    // with the content concerned, the automated-tools flag and the recorded
    // effects (for an appeal reversal). Best-effort: the action happened.
    try {
      if (queueData.itemType === 'quarantinedImage' && action === 'removeContent') {
        // The Vision hold already produced the decision: a person confirmed it.
        await firestore.collection(MODERATION_DECISIONS).doc(queueId).set({
          confirmedBy: moderatorId,
          confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
          automatedDecision: false,
          ...(statementOfReasons ? { reasonCode: statementOfReasons.reasonCode, explanation: statementOfReasons.explanation } : {}),
        }, { merge: true });
      } else {
        const created = await notifyAffectedUserOfDecision({
          queueId,
          userId: queueData.userId || queueData.reportedUserId,
          action: decisionAction,
          reasonCode: decisionReason,
          explanation: statementOfReasons?.explanation ?? notes ?? null,
          moderatorId,
          contentRef: action === 'suspendReporting' ? { type: 'report', id: null, excerpt: null } : contentRef,
          automated,
          effects,
        });
        // Terms 18.6: repeated violations after a warning -> suspension.
        if (created && (action === 'issueWarning' || action === 'removeContent')) {
          const uid = queueData.userId || queueData.reportedUserId;
          if (typeof uid === 'string' && uid) {
            const warning = effects.find((e) => e.type === 'warning') as { warningId: string } | undefined;
            escalation = await escalateIfRepeatOffender({
              userId: uid, decisionId: queueId, currentWarningId: warning?.warningId ?? null, decidedBy: moderatorId,
            });
          }
        }
      }
    } catch (e) {
      console.error(`takeModerationAction: decision notice for ${queueId} failed:`, e);
    }

    return {
      queueId,
      action,
      moderatorId,
      notes,
      statementOfReasons,
      escalation,
      reversal,
      actionAt: admin.firestore.FieldValue.serverTimestamp(),
      success: true,
      errorMessage: null,
    };
  } catch (error: any) {
    console.error('Error taking moderation action:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}));

const MODERATION_ACTIONS = new Set([
  'approve', 'dismiss', 'removeContent', 'issueWarning', 'suspendUser', 'banUser', 'shadowBan', 'requireVerification',
  'suspendReporting',
]);
/** Statuses after which an item is closed (callables: resolved; old panel: completed). */
const FINAL_QUEUE_STATUSES = new Set(['resolved', 'completed', 'dismissed', 'closed', 'actioned']);

/** The reported user of an item; user-targeted actions need one. */
function targetUserId(queueData: any): string {
  const uid = queueData.userId || queueData.reportedUserId;
  if (typeof uid !== 'string' || !uid) {
    throw new functions.https.HttpsError('failed-precondition', 'This item has no reported user to act on');
  }
  return uid;
}

/**
 * Helper: Approve Content
 *
 * flaggedPhoto: marked approved. quarantinedImage (Vision hold): the upload
 * goes back to its original path and the hold decision is reversed (the user
 * is told). Returns the reversal result when there was one.
 */
async function approveContent(queueData: any, moderatorId: string, explanation: string | null): Promise<unknown> {
  if (queueData.itemType === 'flaggedPhoto') {
    await firestore.collection('flagged_photos').doc(queueData.itemId).update({
      moderationStatus: 'approved',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return null;
  }
  if (queueData.itemType === 'quarantinedImage' || (queueData.type === 'image' && queueData.quarantinePath)) {
    const decision = await firestore.collection(MODERATION_DECISIONS).doc(queueData.queueId).get();
    if (decision.exists) {
      return reverseDecisionOnReview(queueData.queueId, moderatorId,
        explanation || 'A moderator reviewed the photo and found no violation. It has been restored.');
    }
    // Held before decisions were recorded: restore the file directly.
    if (typeof queueData.objectPath === 'string' && typeof queueData.quarantinePath === 'string') {
      return restoreQuarantined(queueData.objectPath, queueData.quarantinePath);
    }
  }
  if (queueData.itemType === 'reporterAbuse') await clearReporterReview(queueData.userId);
  return null;
}

/**
 * Helper: Dismiss Report
 */
async function dismissReport(queueData: any): Promise<void> {
  await updateRelatedReports(queueData, { status: 'dismissed' });
  if (queueData.itemType === 'reporterAbuse') await clearReporterReview(queueData.userId);
}

/**
 * Helper: Remove Content
 *
 * Legacy item types (flaggedMessage / flaggedPhoto) plus the report-pipeline
 * items (P1-12): a reported chat message is replaced for everyone, a reported
 * event is cancelled, a reported experience is hidden. Content that cannot be
 * removed from here throws, so the item stays open and the moderator picks
 * another action (it used to be a silent no-op that still resolved the item).
 *
 * Returns the effects (for an appeal reversal): removed message text is kept
 * in moderation_content_backups until the appeal window ends; a strike is
 * recorded for the author (Terms 18.6).
 */
async function removeContent(
  queueData: any,
  moderatorId: string,
  statementOfReasons: StatementOfReasons | null
): Promise<DecisionEffect[]> {
  const queueId: string = queueData.queueId;
  const author = typeof (queueData.userId || queueData.reportedUserId) === 'string'
    ? (queueData.userId || queueData.reportedUserId) as string : '';
  const strike = async (): Promise<DecisionEffect[]> =>
    author ? [await recordStrike({ userId: author, decisionId: queueId, kind: 'content_removal' })] : [];
  const backupUntil = Date.now() + (APPEAL_WINDOW_DAYS + 30) * 86_400_000;
  const moderation = {
    reason: 'moderator_removed',
    reasonCode: statementOfReasons?.reasonCode ?? null,
    queueId: queueData.queueId ?? null,
    removedBy: moderatorId,
    removedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (queueData.itemType === 'quarantinedImage') {
    // Already out of reach (quarantine/): removal = confirming the hold.
    return strike();
  }
  if (queueData.itemType === 'flaggedMessage') {
    await firestore.collection('messages').doc(queueData.itemId).update({
      deleted: true,
      deletedBy: 'moderator',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return [{ type: 'legacyMessage', messageId: queueData.itemId }, ...await strike()];
  }
  if (queueData.itemType === 'flaggedPhoto') {
    await firestore.collection('users').doc(queueData.userId).update({
      photos: admin.firestore.FieldValue.arrayRemove(queueData.metadata.photoUrl),
    });
    return [{ type: 'profilePhoto', userId: queueData.userId, photoUrl: queueData.metadata.photoUrl }, ...await strike()];
  }

  const ref = queueData.contentRef;
  const path: string | null = typeof ref?.path === 'string' ? ref.path : null;
  if (ref?.type === 'message' && path && /^conversations\/[^/]+\/messages\/[^/]+$/.test(path)) {
    const snap = await firestore.doc(path).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'The reported message no longer exists');
    await backupMessage(queueId, path, snap.data() || {}, backupUntil);
    // Same fields the app writes for "delete for everyone".
    await snap.ref.update({
      isDeletedForEveryone: true,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      content: t('en', 'srvMessageRemovedByModerator'),
      // Readers render the placeholder in their own language.
      'metadata.systemKey': 'srvMessageRemovedByModerator',
      // Stored translations of the removed text (translatePrivateText).
      tr: admin.firestore.FieldValue.delete(),
      trHash: admin.firestore.FieldValue.delete(),
      moderation,
    });
    return [{ type: 'message', path, backupId: queueId }, ...await strike()];
  }
  if (ref?.type === 'message' && path && /^(groups|communities|events)\/[^/]+\/messages\/[^/]+$/.test(path)) {
    // P2-8b: auto-flagged shared-chat messages. Each chat type stores the
    // text in its own field; replace whichever one the message has.
    const snap = await firestore.doc(path).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'The flagged message no longer exists');
    const d = snap.data() || {};
    await backupMessage(queueId, path, d, backupUntil);
    const placeholder = t('en', 'srvMessageRemovedByModerator');
    await snap.ref.update({
      isDeletedForEveryone: true,
      isDeleted: true,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(typeof d.text === 'string' ? { text: placeholder } : {}),
      ...(typeof d.content === 'string' ? { content: placeholder } : {}),
      ...(typeof d.caption === 'string' ? { caption: placeholder } : {}),
      'metadata.systemKey': 'srvMessageRemovedByModerator',
      tr: admin.firestore.FieldValue.delete(),
      trHash: admin.firestore.FieldValue.delete(),
      moderation,
    });
    return [{ type: 'message', path, backupId: queueId }, ...await strike()];
  }
  if (ref?.type === 'event' && path && /^events\/[^/]+$/.test(path)) {
    const snap = await firestore.doc(path).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'The reported event no longer exists');
    const previousStatus = snap.data()?.status ?? null;
    await snap.ref.update({
      status: 'cancelled',
      moderation: { ...moderation, previousStatus },
    });
    return [{ type: 'listingStatus', path, previousStatus }, ...await strike()];
  }
  if (ref?.type === 'experience' && path && /^user_experiences\/[^/]+$/.test(path)) {
    const snap = await firestore.doc(path).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'The reported experience no longer exists');
    const prev = snap.data()?.status;
    const previousStatus = prev === 'published' ? 'published' : 'draft';
    await snap.ref.update({
      status: 'hidden',
      moderation: { ...moderation, previousStatus },
    });
    return [{ type: 'listingStatus', path, previousStatus }, ...await strike()];
  }
  throw new functions.https.HttpsError(
    'failed-precondition',
    'This report type has no removable content here; use a user action (warn, suspend, ban) or dismiss'
  );
}

/**
 * Helper: Issue Warning (+ strike). Repeat-offender escalation (Terms 18.6)
 * runs after the decision is recorded (safety/repeatOffenders.ts).
 */
async function issueWarningToUser(
  userId: string,
  queueData: any,
  notes: string | null,
  decisionId: string,
  moderatorId: string
): Promise<DecisionEffect[]> {
  return [
    await recordWarning({
      userId,
      reason: queueData.metadata?.category || queueData.reasonCode || 'Policy violation',
      description: notes || 'Content violated community guidelines',
      severity: 'moderate',
      decisionId,
      by: moderatorId,
    }),
    await recordStrike({ userId, decisionId, kind: 'warning' }),
  ];
}

/**
 * Helper: Shadow Ban User
 */
async function shadowBanUser(userId: string): Promise<DecisionEffect> {
  await firestore.collection('users').doc(userId).update({
    isShadowBanned: true,
    shadowBannedAt: admin.firestore.FieldValue.serverTimestamp(),
    visibilityReduction: 0.9,
  });
  return { type: 'shadowBan', userId };
}

/**
 * Helper: Require Verification
 */
async function requireVerification(userId: string): Promise<DecisionEffect> {
  await firestore.collection('users').doc(userId).update({
    verificationRequired: true,
    verificationRequiredAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { type: 'verification', userId };
}

/**
 * Bulk Moderation Action
 * Point 249: Process multiple items at once
 */
export const executeBulkModeration = functions.runWith({ memory: '512MB' }).https.onCall(monitored("executeBulkModeration", async (data, context) => {
  await verifyModeratorPermission(context);

  const { queueIds, action, notes = null } = data || {};
  const moderatorId = context.auth!.uid;
  if (!Array.isArray(queueIds) || queueIds.length === 0 || queueIds.length > 100) {
    throw new functions.https.HttpsError('invalid-argument', 'queueIds must be an array of 1-100 ids');
  }
  const statementOfReasons = parseStatementOfReasons(data);

  try {
    const operationRef = firestore.collection('bulk_moderation_operations').doc();
    await operationRef.set({
      operationId: operationRef.id,
      queueIds,
      action,
      moderatorId,
      notes,
      statementOfReasons,
      initiatedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      totalItems: queueIds.length,
      processedItems: 0,
      successCount: 0,
      failureCount: 0,
      results: [],
    });

    // Process each item (in production, use Cloud Tasks for better reliability)
    const results = [];
    let successCount = 0;
    let failureCount = 0;

    for (const queueId of queueIds) {
      try {
        await takeModerationAction.run(
          { queueId, action, notes, parameters: data.parameters || {}, ...(statementOfReasons || {}) },
          context
        );
        results.push({ queueId, success: true, errorMessage: null });
        successCount++;
      } catch (err: any) {
        results.push({ queueId, success: false, errorMessage: err.message });
        failureCount++;
      }
    }

    // Update operation status
    await operationRef.update({
      status: 'completed',
      processedItems: queueIds.length,
      successCount,
      failureCount,
      results,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      operationId: operationRef.id,
      status: 'completed',
      totalItems: queueIds.length,
      successCount,
      failureCount,
      results,
    };
  } catch (error: any) {
    console.error('Error executing bulk moderation:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}));

/**
 * Get Moderation Statistics
 * Point 250: Dashboard metrics for moderation
 */
export const getModerationStatistics = functions
  .runWith({ memory: '512MB' })
  .https.onCall(monitored("getModerationStatistics", async (data, context) => {
  await verifyModeratorPermission(context);

  try {
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Pending reports
    const pendingSnapshot = await firestore
      .collection('moderation_queue')
      .where('status', '==', 'pending')
      .count()
      .get();

    // Assigned reports
    const assignedSnapshot = await firestore
      .collection('moderation_queue')
      .where('status', '==', 'assigned')
      .count()
      .get();

    // Resolved today
    const resolvedTodaySnapshot = await firestore
      .collection('moderation_queue')
      .where('status', '==', 'resolved')
      .where('resolvedAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    // Resolved this week
    const resolvedWeekSnapshot = await firestore
      .collection('moderation_queue')
      .where('status', '==', 'resolved')
      .where('resolvedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    // Resolved this month
    const resolvedMonthSnapshot = await firestore
      .collection('moderation_queue')
      .where('status', '==', 'resolved')
      .where('resolvedAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    // Get reports by category
    const allReportsSnapshot = await firestore
      .collection('user_reports')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .get();

    const reportsByCategory: { [key: string]: number } = {};
    allReportsSnapshot.docs.forEach(doc => {
      const category = doc.data().category;
      reportsByCategory[category] = (reportsByCategory[category] || 0) + 1;
    });

    // Get actions by type
    const actionsSnapshot = await firestore
      .collection('moderation_actions_log')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .get();

    const actionsByType: { [key: string]: number } = {};
    actionsSnapshot.docs.forEach(doc => {
      const action = doc.data().action;
      actionsByType[action] = (actionsByType[action] || 0) + 1;
    });

    return {
      totalPendingReports: pendingSnapshot.data().count,
      totalAssignedReports: assignedSnapshot.data().count,
      totalResolvedToday: resolvedTodaySnapshot.data().count,
      totalResolvedWeek: resolvedWeekSnapshot.data().count,
      totalResolvedMonth: resolvedMonthSnapshot.data().count,
      avgResolutionTime: 0, // Calculate from timestamps
      reportsByCategory,
      actionsByType,
      moderatorStats: {},
      trendingIssues: [],
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error: any) {
    console.error('Error getting moderation statistics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}));
