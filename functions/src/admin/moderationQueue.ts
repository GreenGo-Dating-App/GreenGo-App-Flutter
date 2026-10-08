/**
 * Moderation Queue Cloud Functions
 * Points 246-250: Content moderation queue management
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { MODERATION_ROLES, requireAdmin } from '../shared/adminAuth';
import { syncHostExperiencesForBan } from '../user_experiences/hostBan';

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
    if (queueData.itemType === 'userReport') {
      const reportDoc = await firestore.collection('user_reports').doc(queueData.itemId).get();
      content = reportDoc.data();
    } else if (queueData.itemType === 'flaggedPhoto') {
      const photoDoc = await firestore.collection('flagged_photos').doc(queueData.itemId).get();
      content = photoDoc.data();
    } else if (queueData.itemType === 'flaggedMessage') {
      const messageDoc = await firestore.collection('messages').doc(queueData.itemId).get();
      content = messageDoc.data();
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
  const queueData = queueDoc.data()!;
  if (FINAL_QUEUE_STATUSES.has(queueData.status)) {
    throw new functions.https.HttpsError('failed-precondition', `Queue item is already ${queueData.status}`);
  }

  // Execute the action FIRST. If it fails the item stays open (it used to be
  // marked resolved anyway, so a failed ban looked like a handled report).
  const reasonText = statementOfReasons?.explanation ?? notes;
  try {
    switch (action) {
      case 'approve':
        await approveContent(queueData);
        break;
      case 'dismiss':
        await dismissReport(queueData);
        break;
      case 'removeContent':
        await removeContent(queueData, moderatorId, statementOfReasons);
        break;
      case 'issueWarning':
        await issueWarningToUser(targetUserId(queueData), queueData, reasonText);
        break;
      case 'suspendUser': {
        const durationDays = Number(parameters.durationDays) > 0 ? Number(parameters.durationDays) : 7;
        await suspendUser(targetUserId(queueData), reasonText, durationDays);
        break;
      }
      case 'banUser':
        await banUser(targetUserId(queueData), reasonText);
        break;
      case 'shadowBan':
        await shadowBanUser(targetUserId(queueData));
        break;
      case 'requireVerification':
        await requireVerification(targetUserId(queueData));
        break;
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
          automated: false,
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

    return {
      queueId,
      action,
      moderatorId,
      notes,
      statementOfReasons,
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

/** Best-effort mirror of an account restriction onto profiles/{uid} (what the panel's Users page reads). */
async function mirrorProfileStatus(userId: string, patch: Record<string, unknown>): Promise<void> {
  try {
    await firestore.collection('profiles').doc(userId).update(patch);
  } catch (e: any) {
    if (e?.code !== 5) console.error(`Could not mirror status onto profiles/${userId}:`, e?.message || e);
  }
}

/**
 * Helper: Approve Content
 */
async function approveContent(queueData: any): Promise<void> {
  if (queueData.itemType === 'flaggedPhoto') {
    await firestore.collection('flagged_photos').doc(queueData.itemId).update({
      moderationStatus: 'approved',
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

/**
 * Helper: Dismiss Report
 */
async function dismissReport(queueData: any): Promise<void> {
  await updateRelatedReports(queueData, { status: 'dismissed' });
}

/**
 * Helper: Remove Content
 *
 * Legacy item types (flaggedMessage / flaggedPhoto) plus the report-pipeline
 * items (P1-12): a reported chat message is replaced for everyone, a reported
 * event is cancelled, a reported experience is hidden. Content that cannot be
 * removed from here throws, so the item stays open and the moderator picks
 * another action (it used to be a silent no-op that still resolved the item).
 */
async function removeContent(
  queueData: any,
  moderatorId: string,
  statementOfReasons: StatementOfReasons | null
): Promise<void> {
  const moderation = {
    reason: 'moderator_removed',
    reasonCode: statementOfReasons?.reasonCode ?? null,
    queueId: queueData.queueId ?? null,
    removedBy: moderatorId,
    removedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (queueData.itemType === 'flaggedMessage') {
    await firestore.collection('messages').doc(queueData.itemId).update({
      deleted: true,
      deletedBy: 'moderator',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }
  if (queueData.itemType === 'flaggedPhoto') {
    await firestore.collection('users').doc(queueData.userId).update({
      photos: admin.firestore.FieldValue.arrayRemove(queueData.metadata.photoUrl),
    });
    return;
  }

  const ref = queueData.contentRef;
  const path: string | null = typeof ref?.path === 'string' ? ref.path : null;
  if (ref?.type === 'message' && path && /^conversations\/[^/]+\/messages\/[^/]+$/.test(path)) {
    // Same fields the app writes for "delete for everyone".
    await firestore.doc(path).update({
      isDeletedForEveryone: true,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      content: 'This message was removed by a moderator',
      moderation,
    });
    return;
  }
  if (ref?.type === 'event' && path && /^events\/[^/]+$/.test(path)) {
    const snap = await firestore.doc(path).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'The reported event no longer exists');
    await snap.ref.update({
      status: 'cancelled',
      moderation: { ...moderation, previousStatus: snap.data()?.status ?? null },
    });
    return;
  }
  if (ref?.type === 'experience' && path && /^user_experiences\/[^/]+$/.test(path)) {
    const snap = await firestore.doc(path).get();
    if (!snap.exists) throw new functions.https.HttpsError('not-found', 'The reported experience no longer exists');
    const prev = snap.data()?.status;
    await snap.ref.update({
      status: 'hidden',
      moderation: { ...moderation, previousStatus: prev === 'published' ? 'published' : 'draft' },
    });
    return;
  }
  throw new functions.https.HttpsError(
    'failed-precondition',
    'This report type has no removable content here; use a user action (warn, suspend, ban) or dismiss'
  );
}

/**
 * Helper: Issue Warning
 */
async function issueWarningToUser(
  userId: string,
  queueData: any,
  notes: string | null
): Promise<void> {
  await firestore.collection('user_warnings').add({
    userId,
    reason: queueData.metadata?.category || queueData.reasonCode || 'Policy violation',
    description: notes || 'Content violated community guidelines',
    severity: 'moderate',
    issuedAt: admin.firestore.FieldValue.serverTimestamp(),
    acknowledged: false,
  });
}

/**
 * Helper: Suspend User
 */
async function suspendUser(
  userId: string,
  reason: string | null,
  durationDays: number
): Promise<void> {
  const suspendedUntil = new Date();
  suspendedUntil.setDate(suspendedUntil.getDate() + durationDays);

  await firestore.collection('users').doc(userId).update({
    accountStatus: 'suspended',
    suspensionReason: reason || 'Policy violation',
    suspendedUntil: admin.firestore.Timestamp.fromDate(suspendedUntil),
    suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await mirrorProfileStatus(userId, {
    status: 'suspended',
    suspensionReason: reason || 'Policy violation',
    suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
    suspendedUntil: admin.firestore.Timestamp.fromDate(suspendedUntil),
  });
  await syncHostExperiencesForBan(userId, true);
}

/**
 * Helper: Ban User
 */
async function banUser(userId: string, reason: string | null): Promise<void> {
  await firestore.collection('users').doc(userId).update({
    accountStatus: 'banned',
    banReason: reason || 'Severe policy violation',
    bannedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await admin.auth().updateUser(userId, { disabled: true });
  await mirrorProfileStatus(userId, {
    status: 'banned',
    banReason: reason || 'Severe policy violation',
    bannedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await syncHostExperiencesForBan(userId, true);
}

/**
 * Helper: Shadow Ban User
 */
async function shadowBanUser(userId: string): Promise<void> {
  await firestore.collection('users').doc(userId).update({
    isShadowBanned: true,
    shadowBannedAt: admin.firestore.FieldValue.serverTimestamp(),
    visibilityReduction: 0.9,
  });
}

/**
 * Helper: Require Verification
 */
async function requireVerification(userId: string): Promise<void> {
  await firestore.collection('users').doc(userId).update({
    verificationRequired: true,
    verificationRequiredAt: admin.firestore.FieldValue.serverTimestamp(),
  });
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
