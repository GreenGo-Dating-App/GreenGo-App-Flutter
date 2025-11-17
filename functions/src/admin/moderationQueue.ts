/**
 * Moderation Queue Cloud Functions
 * Points 246-250: Content moderation queue management
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();

/**
 * Verify Moderator Permission Helper
 */
async function verifyModeratorPermission(
  context: functions.https.CallableContext
): Promise<void> {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const customClaims = context.auth.token;
  if (!customClaims.moderator && !customClaims.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only moderators can access moderation queue'
    );
  }
}

/**
 * Log Moderation Action Helper
 */
async function logModerationAction(
  moderatorId: string,
  queueId: string,
  action: string,
  notes: string | null
): Promise<void> {
  await firestore.collection('moderation_actions_log').add({
    moderatorId,
    queueId,
    action,
    notes,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Get Moderation Queue
 * Point 246: Fetch pending reports for review
 */
export const getModerationQueue = functions.https.onCall(async (data, context) => {
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
});

/**
 * Get Moderation Review Item
 * Point 247: Detailed review interface with context
 */
export const getModerationReviewItem = functions.https.onCall(async (data, context) => {
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
    }

    // Get user context
    const userDoc = await firestore.collection('users').doc(queueData.userId).get();
    const userData = userDoc.data()!;

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
    for (const reportId of queueData.relatedReportIds) {
      const reportDoc = await firestore.collection('user_reports').doc(reportId).get();
      if (reportDoc.exists) {
        const reportData = reportDoc.data()!;
        relatedReports.push({
          reportId,
          reporterId: reportData.reporterId,
          category: reportData.category,
          description: reportData.description,
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
        text: content?.description || content?.text || null,
        photoUrls: content?.screenshotUrls || content?.photoUrls || [],
        additionalData: content || {},
        createdAt: content?.createdAt || queueData.addedAt,
      },
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
});

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
export const assignModerationItem = functions.https.onCall(async (data, context) => {
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
});

/**
 * Take Moderation Action
 * Point 248: Execute moderation decision
 */
export const takeModerationAction = functions.https.onCall(async (data, context) => {
  await verifyModeratorPermission(context);

  const { queueId, action, notes = null, parameters = {} } = data;
  const moderatorId = context.auth!.uid;

  try {
    const queueDoc = await firestore.collection('moderation_queue').doc(queueId).get();

    if (!queueDoc.exists) {
      throw new Error('Queue item not found');
    }

    const queueData = queueDoc.data()!;

    // Execute the action
    let success = true;
    let errorMessage = null;

    try {
      switch (action) {
        case 'approve':
          // Mark content as approved
          await approveContent(queueData);
          break;

        case 'dismiss':
          // Dismiss report as invalid
          await dismissReport(queueData);
          break;

        case 'removeContent':
          // Delete the flagged content
          await removeContent(queueData);
          break;

        case 'issueWarning':
          // Issue warning to user
          await issueWarningToUser(queueData.userId, queueData, notes);
          break;

        case 'suspendUser':
          // Suspend user account
          const durationDays = parameters.durationDays || 7;
          await suspendUser(queueData.userId, notes, durationDays);
          break;

        case 'banUser':
          // Ban user account
          await banUser(queueData.userId, notes);
          break;

        case 'shadowBan':
          // Shadow ban user
          await shadowBanUser(queueData.userId);
          break;

        case 'requireVerification':
          // Require user to verify identity
          await requireVerification(queueData.userId);
          break;

        default:
          throw new Error(`Unknown action: ${action}`);
      }
    } catch (err: any) {
      success = false;
      errorMessage = err.message;
    }

    // Update queue item status
    await firestore.collection('moderation_queue').doc(queueId).update({
      status: 'resolved',
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedBy: moderatorId,
      action,
      moderatorNotes: notes,
    });

    // Update all related reports
    for (const reportId of queueData.relatedReportIds) {
      await firestore.collection('user_reports').doc(reportId).update({
        status: 'resolved',
        action,
        reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderatorNotes: notes,
      });
    }

    // Log moderation action
    await logModerationAction(moderatorId, queueId, action, notes);

    // Log to admin audit
    await firestore.collection('admin_audit_log').add({
      adminId: moderatorId,
      action: 'reviewedReport',
      targetType: 'moderation_queue',
      targetId: queueId,
      details: { action, notes, userId: queueData.userId },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      queueId,
      action,
      moderatorId,
      notes,
      actionAt: admin.firestore.FieldValue.serverTimestamp(),
      success,
      errorMessage,
    };
  } catch (error: any) {
    console.error('Error taking moderation action:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

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
  for (const reportId of queueData.relatedReportIds) {
    await firestore.collection('user_reports').doc(reportId).update({
      status: 'dismissed',
    });
  }
}

/**
 * Helper: Remove Content
 */
async function removeContent(queueData: any): Promise<void> {
  if (queueData.itemType === 'flaggedMessage') {
    await firestore.collection('messages').doc(queueData.itemId).update({
      deleted: true,
      deletedBy: 'moderator',
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else if (queueData.itemType === 'flaggedPhoto') {
    await firestore.collection('users').doc(queueData.userId).update({
      photos: admin.firestore.FieldValue.arrayRemove(queueData.metadata.photoUrl),
    });
  }
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
    reason: queueData.metadata.category || 'Policy violation',
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
export const executeBulkModeration = functions.https.onCall(async (data, context) => {
  await verifyModeratorPermission(context);

  const { queueIds, action, notes = null } = data;
  const moderatorId = context.auth!.uid;

  try {
    const operationRef = firestore.collection('bulk_moderation_operations').doc();
    await operationRef.set({
      operationId: operationRef.id,
      queueIds,
      action,
      moderatorId,
      notes,
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
        await takeModerationAction.run({ queueId, action, notes }, context);
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
});

/**
 * Get Moderation Statistics
 * Point 250: Dashboard metrics for moderation
 */
export const getModerationStatistics = functions.https.onCall(async (data, context) => {
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
});
