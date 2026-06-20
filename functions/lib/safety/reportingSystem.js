"use strict";
/**
 * Reporting & Blocking System Cloud Functions
 * Points 208-220: User reporting, blocking, and moderation workflow
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getBlockList = exports.unblockUser = exports.blockUser = exports.submitAppeal = exports.reviewReport = exports.issueWarning = exports.submitReport = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
/**
 * Submit User Report
 * Points 211-213: Comprehensive reporting with anonymous option
 */
exports.submitReport = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { reportedUserId, category, description, screenshotUrls = [], conversationId, messageId, isAnonymous = true, // Point 213: Anonymous reporting by default
     } = data;
    const reporterId = context.auth.uid;
    try {
        // Validate report category
        const validCategories = [
            'inappropriateContent',
            'harassment',
            'scam',
            'fakeProfile',
            'spam',
            'hateSpeech',
            'violence',
            'minorSafety',
            'impersonation',
            'other',
        ];
        if (!validCategories.includes(category)) {
            throw new Error('Invalid report category');
        }
        // Determine priority (Point 214)
        const priority = calculateReportPriority(category, description);
        // Create report
        const reportRef = firestore.collection('user_reports').doc();
        const report = {
            reportId: reportRef.id,
            reporterId: isAnonymous ? 'anonymous' : reporterId, // Point 213
            reportedUserId,
            category,
            description,
            screenshotUrls,
            conversationId: conversationId || null,
            messageId: messageId || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending',
            priority,
            assignedModeratorId: null,
            reviewedAt: null,
            moderatorNotes: null,
            action: null,
        };
        await reportRef.set(report);
        // Add to moderation queue (Point 214)
        await firestore.collection('moderation_queue').add({
            queueId: reportRef.id,
            itemType: 'userReport',
            itemId: reportRef.id,
            userId: reportedUserId,
            priority,
            addedAt: admin.firestore.FieldValue.serverTimestamp(),
            assignedTo: null,
            relatedReportIds: [reportRef.id],
            metadata: {
                category,
                reporterId: isAnonymous ? 'anonymous' : reporterId,
            },
        });
        // Check if user has high report volume (Point 218)
        const reportCount = await firestore
            .collection('user_reports')
            .where('reportedUserId', '==', reportedUserId)
            .where('status', '==', 'pending')
            .count()
            .get();
        if (reportCount.data().count >= 10) {
            // Automatic blocking for high report volume
            await automaticBlockUser(reportedUserId, 'High report volume (10+ reports)');
        }
        // For critical reports, issue immediate warning (Point 208)
        if (priority === 'critical' && category === 'minorSafety') {
            await (0, exports.issueWarning)(reportedUserId, 'minorSafety', description, 'severe');
        }
        return {
            reportId: reportRef.id,
            status: 'submitted',
            priority,
        };
    }
    catch (error) {
        console.error('Error submitting report:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Issue Warning to User
 * Point 208: Automated warning system for first-time offenses
 */
const issueWarning = async (userId, reason, description, severity) => {
    // Check warning history
    const warningsSnapshot = await firestore
        .collection('user_warnings')
        .where('userId', '==', userId)
        .orderBy('issuedAt', 'desc')
        .limit(5)
        .get();
    const warningCount = warningsSnapshot.size;
    // Determine severity based on history
    let finalSeverity = severity;
    if (warningCount === 0) {
        finalSeverity = 'minor'; // First-time offense
    }
    else if (warningCount >= 3) {
        finalSeverity = 'final'; // Last warning before ban
    }
    // Create warning
    await firestore.collection('user_warnings').add({
        userId,
        reason,
        description,
        severity: finalSeverity,
        issuedAt: admin.firestore.FieldValue.serverTimestamp(),
        acknowledged: false,
        acknowledgedAt: null,
    });
    // If final warning, suspend account temporarily
    if (finalSeverity === 'final') {
        await firestore.collection('users').doc(userId).update({
            accountStatus: 'suspended',
            suspendedUntil: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
            ),
        });
    }
};
exports.issueWarning = issueWarning;
/**
 * Review Report (Moderator Action)
 * Point 209: Escalation to human moderators
 */
exports.reviewReport = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Check if user is a moderator
    const customClaims = context.auth.token;
    if (!customClaims.moderator && !customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Only moderators can review reports');
    }
    const { reportId, action, moderatorNotes } = data;
    const moderatorId = context.auth.uid;
    try {
        const reportRef = firestore.collection('user_reports').doc(reportId);
        const reportDoc = await reportRef.get();
        if (!reportDoc.exists) {
            throw new Error('Report not found');
        }
        const report = reportDoc.data();
        // Update report
        await reportRef.update({
            status: 'resolved',
            action,
            assignedModeratorId: moderatorId,
            reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
            moderatorNotes,
        });
        // Execute action
        switch (action) {
            case 'warningIssued':
                await (0, exports.issueWarning)(report.reportedUserId, report.category, moderatorNotes, 'moderate');
                break;
            case 'contentRemoved':
                if (report.messageId) {
                    await firestore.collection('messages').doc(report.messageId).update({
                        deleted: true,
                        deletedBy: 'moderator',
                        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
                break;
            case 'accountSuspended':
                await firestore.collection('users').doc(report.reportedUserId).update({
                    accountStatus: 'suspended',
                    suspendedUntil: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
                    ),
                });
                break;
            case 'accountBanned':
                await firestore.collection('users').doc(report.reportedUserId).update({
                    accountStatus: 'banned',
                    bannedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            case 'shadowBanned':
                // Point 219: Shadow banning
                await shadowBanUser(report.reportedUserId);
                break;
        }
        return { success: true, action };
    }
    catch (error) {
        console.error('Error reviewing report:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Submit Appeal
 * Point 210: Content appeal process
 */
exports.submitAppeal = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { reportId, appealReason, evidenceUrls = [] } = data;
    const userId = context.auth.uid;
    try {
        // Verify the report exists and is for this user
        const reportDoc = await firestore
            .collection('user_reports')
            .doc(reportId)
            .get();
        if (!reportDoc.exists) {
            throw new Error('Report not found');
        }
        const report = reportDoc.data();
        if (report.reportedUserId !== userId) {
            throw new Error('You can only appeal reports against your account');
        }
        // Create appeal
        const appealRef = firestore.collection('report_appeals').doc();
        await appealRef.set({
            appealId: appealRef.id,
            reportId,
            userId,
            appealReason,
            evidenceUrls,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending',
            reviewerNotes: null,
            reviewedAt: null,
            decision: null,
        });
        // Update report status
        await firestore.collection('user_reports').doc(reportId).update({
            status: 'appealed',
        });
        // Add to moderation queue
        await firestore.collection('moderation_queue').add({
            itemType: 'appeal',
            itemId: appealRef.id,
            userId,
            priority: 'medium',
            addedAt: admin.firestore.FieldValue.serverTimestamp(),
            assignedTo: null,
            relatedReportIds: [reportId],
            metadata: {
                originalReportId: reportId,
            },
        });
        return {
            appealId: appealRef.id,
            status: 'submitted',
        };
    }
    catch (error) {
        console.error('Error submitting appeal:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Block User
 * Points 215-217: User blocking functionality
 */
exports.blockUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { blockedUserId, reason } = data;
    const blockerId = context.auth.uid;
    try {
        // Check if already blocked
        const existingBlock = await firestore
            .collection('user_blocks')
            .where('blockerId', '==', blockerId)
            .where('blockedUserId', '==', blockedUserId)
            .where('isActive', '==', true)
            .get();
        if (!existingBlock.empty) {
            throw new Error('User already blocked');
        }
        // Check if this creates mutual block (Point 217)
        const reverseBlock = await firestore
            .collection('user_blocks')
            .where('blockerId', '==', blockedUserId)
            .where('blockedUserId', '==', blockerId)
            .where('isActive', '==', true)
            .get();
        const isMutual = !reverseBlock.empty;
        const blockType = isMutual ? 'mutual' : 'manual';
        // Create block
        const blockRef = firestore.collection('user_blocks').doc();
        await blockRef.set({
            blockId: blockRef.id,
            blockerId,
            blockedUserId,
            type: blockType,
            reason: reason || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isActive: true,
        });
        // If mutual, update the reverse block type
        if (isMutual) {
            await reverseBlock.docs[0].ref.update({
                type: 'mutual',
            });
        }
        // Remove any existing matches
        const matchesSnapshot = await firestore
            .collection('matches')
            .where('users', 'array-contains', blockerId)
            .get();
        const batch = firestore.batch();
        matchesSnapshot.docs.forEach((doc) => {
            const matchData = doc.data();
            if (matchData.users.includes(blockedUserId)) {
                batch.delete(doc.ref);
            }
        });
        await batch.commit();
        return {
            blockId: blockRef.id,
            type: blockType,
            success: true,
        };
    }
    catch (error) {
        console.error('Error blocking user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Unblock User
 * Point 216: Block list management
 */
exports.unblockUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { blockedUserId } = data;
    const blockerId = context.auth.uid;
    try {
        const blockSnapshot = await firestore
            .collection('user_blocks')
            .where('blockerId', '==', blockerId)
            .where('blockedUserId', '==', blockedUserId)
            .where('isActive', '==', true)
            .get();
        if (blockSnapshot.empty) {
            throw new Error('Block not found');
        }
        await blockSnapshot.docs[0].ref.update({
            isActive: false,
            unblockedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        console.error('Error unblocking user:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get Block List
 * Point 216: View blocked users
 */
exports.getBlockList = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const blocksSnapshot = await firestore
            .collection('user_blocks')
            .where('blockerId', '==', userId)
            .where('isActive', '==', true)
            .orderBy('createdAt', 'desc')
            .get();
        const blocks = blocksSnapshot.docs.map((doc) => doc.data());
        return {
            blocks,
            totalBlocked: blocks.length,
        };
    }
    catch (error) {
        console.error('Error getting block list:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Automatic Blocking for High Report Volume
 * Point 218: Automatic blocking threshold
 */
async function automaticBlockUser(userId, reason) {
    await firestore.collection('user_blocks').add({
        blockerId: 'system',
        blockedUserId: userId,
        type: 'automatic',
        reason,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
    });
    // Update user account status
    await firestore.collection('users').doc(userId).update({
        accountStatus: 'restricted',
        restrictionReason: reason,
    });
}
/**
 * Shadow Ban User
 * Point 219: Reduce visibility without notification
 */
async function shadowBanUser(userId) {
    await firestore.collection('user_blocks').add({
        blockerId: 'system',
        blockedUserId: userId,
        type: 'shadowBan',
        reason: 'Suspicious activity detected',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
    });
    // Update user visibility settings
    await firestore.collection('users').doc(userId).update({
        isShadowBanned: true,
        shadowBannedAt: admin.firestore.FieldValue.serverTimestamp(),
        visibilityReduction: 0.9, // 90% reduction in visibility
    });
}
/**
 * Calculate Report Priority
 * Point 214: Priority sorting by severity
 */
function calculateReportPriority(category, description) {
    // Critical priority
    if (category === 'minorSafety' ||
        category === 'violence' ||
        description.toLowerCase().includes('threat')) {
        return 'critical';
    }
    // High priority
    if (category === 'harassment' ||
        category === 'scam' ||
        category === 'hateSpeech') {
        return 'high';
    }
    // Medium priority
    if (category === 'inappropriateContent' || category === 'fakeProfile') {
        return 'medium';
    }
    // Low priority
    return 'low';
}
//# sourceMappingURL=reportingSystem.js.map