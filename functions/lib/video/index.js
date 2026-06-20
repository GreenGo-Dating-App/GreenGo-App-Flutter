"use strict";
/**
 * Video Calling Service
 * 21 Cloud Functions for managing video calls using Agora.io
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
exports.archiveOldCallRecords = exports.cleanupAbandonedCalls = exports.cleanupMissedCalls = exports.onCallEnded = exports.onCallStarted = exports.getCallAnalytics = exports.getCallHistory = exports.removeFromGroupCall = exports.inviteToGroupCall = exports.joinGroupCall = exports.createGroupCall = exports.sendCallReaction = exports.shareScreen = exports.toggleVideo = exports.muteParticipant = exports.startCallRecording = exports.endCall = exports.rejectCall = exports.answerCall = exports.initiateCall = exports.generateAgoraToken = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const agora_access_token_1 = require("agora-access-token");
const types_1 = require("../shared/types");
// Agora Configuration (these should be in environment variables)
const AGORA_APP_ID = process.env.AGORA_APP_ID || '';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';
// Call Configuration
const TOKEN_EXPIRATION_TIME = 3600; // 1 hour
const MAX_CALL_DURATION = 4 * 60 * 60; // 4 hours
const MAX_GROUP_CALL_PARTICIPANTS = 50;
const RECORDING_BUCKET = process.env.RECORDING_BUCKET || 'call-recordings';
// ========== 1. GENERATE AGORA TOKEN (HTTP Callable) ==========
exports.generateAgoraToken = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { channelName, uid: agoraUid, role = 'publisher' } = request.data;
        if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
            throw new Error('Agora credentials not configured');
        }
        (0, utils_1.logInfo)(`Generating Agora token for user ${uid}, channel: ${channelName}`);
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpiredTs = currentTimestamp + TOKEN_EXPIRATION_TIME;
        const tokenRole = role === 'publisher' ? agora_access_token_1.RtcRole.PUBLISHER : agora_access_token_1.RtcRole.SUBSCRIBER;
        const token = agora_access_token_1.RtcTokenBuilder.buildTokenWithUid(AGORA_APP_ID, AGORA_APP_CERTIFICATE, channelName, agoraUid, tokenRole, privilegeExpiredTs);
        return {
            success: true,
            token,
            appId: AGORA_APP_ID,
            channelName,
            uid: agoraUid,
            expiresAt: privilegeExpiredTs,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error generating Agora token:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 2. INITIATE CALL (HTTP Callable) ==========
exports.initiateCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { recipientId, callType, videoEnabled = true } = request.data;
        (0, utils_1.logInfo)(`Initiating call from ${uid} to ${recipientId}`);
        // Check if recipient exists
        const recipientDoc = await utils_1.db.collection('users').doc(recipientId).get();
        if (!recipientDoc.exists) {
            throw new Error('Recipient not found');
        }
        // Check if recipient is blocked or has blocked caller
        const blockSnapshot = await utils_1.db
            .collection('blocks')
            .where('blockerId', 'in', [uid, recipientId])
            .where('blockedId', 'in', [uid, recipientId])
            .get();
        if (!blockSnapshot.empty) {
            throw new Error('Cannot call this user');
        }
        // Generate unique channel name
        const channelName = `call_${uid}_${recipientId}_${Date.now()}`;
        const agoraUid = Math.floor(Math.random() * 1000000);
        // Create call document
        const callRef = await utils_1.db.collection('calls').add({
            channelName,
            callerId: uid,
            recipientId,
            callType,
            videoEnabled,
            status: types_1.CallStatus.RINGING,
            participants: [
                {
                    userId: uid,
                    agoraUid,
                    role: 'caller',
                    joinedAt: null,
                    leftAt: null,
                },
            ],
            startedAt: null,
            endedAt: null,
            duration: 0,
            recordingEnabled: false,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Send notification to recipient
        await utils_1.db.collection('notifications').add({
            userId: recipientId,
            type: 'incoming_call',
            title: 'Incoming Call',
            body: `You have an incoming ${callType} call`,
            data: {
                callId: callRef.id,
                callerId: uid,
                callType,
                videoEnabled,
                channelName,
            },
            read: false,
            sent: false,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        (0, utils_1.logInfo)(`Call initiated: ${callRef.id}`);
        return {
            success: true,
            callId: callRef.id,
            channelName,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error initiating call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 3. ANSWER CALL (HTTP Callable) ==========
exports.answerCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId } = request.data;
        (0, utils_1.logInfo)(`User ${uid} answering call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.recipientId !== uid) {
            throw new Error('Not authorized to answer this call');
        }
        if (callData.status !== types_1.CallStatus.RINGING) {
            throw new Error('Call is not in ringing state');
        }
        const agoraUid = Math.floor(Math.random() * 1000000);
        // Update call status
        await callRef.update({
            status: types_1.CallStatus.ACTIVE,
            startedAt: utils_1.FieldValue.serverTimestamp(),
            participants: utils_1.FieldValue.arrayUnion({
                userId: uid,
                agoraUid,
                role: 'recipient',
                joinedAt: utils_1.FieldValue.serverTimestamp(),
                leftAt: null,
            }),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        (0, utils_1.logInfo)(`Call answered: ${callId}`);
        return {
            success: true,
            callId,
            channelName: callData.channelName,
            agoraUid,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error answering call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 4. REJECT CALL (HTTP Callable) ==========
exports.rejectCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId } = request.data;
        (0, utils_1.logInfo)(`User ${uid} rejecting call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.recipientId !== uid) {
            throw new Error('Not authorized to reject this call');
        }
        await callRef.update({
            status: types_1.CallStatus.REJECTED,
            endedAt: utils_1.FieldValue.serverTimestamp(),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Notify caller
        await utils_1.db.collection('notifications').add({
            userId: callData.callerId,
            type: 'call_rejected',
            title: 'Call Rejected',
            body: 'Your call was rejected',
            data: { callId },
            read: false,
            sent: false,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error rejecting call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 5. END CALL (HTTP Callable) ==========
exports.endCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId } = request.data;
        (0, utils_1.logInfo)(`User ${uid} ending call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        // Update participant's left time
        const participants = callData.participants || [];
        const updatedParticipants = participants.map((p) => {
            if (p.userId === uid && !p.leftAt) {
                return Object.assign(Object.assign({}, p), { leftAt: utils_1.FieldValue.serverTimestamp() });
            }
            return p;
        });
        // Check if all participants have left
        const allLeft = updatedParticipants.every((p) => p.leftAt !== null);
        const updateData = {
            participants: updatedParticipants,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        };
        if (allLeft) {
            updateData.status = types_1.CallStatus.ENDED;
            updateData.endedAt = utils_1.FieldValue.serverTimestamp();
            // Calculate duration
            if (callData.startedAt) {
                const duration = Math.floor((Date.now() - callData.startedAt.toMillis()) / 1000);
                updateData.duration = duration;
            }
        }
        await callRef.update(updateData);
        (0, utils_1.logInfo)(`Call ended: ${callId}`);
        return { success: true, allEnded: allLeft };
    }
    catch (error) {
        (0, utils_1.logError)('Error ending call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 6. START CALL RECORDING (HTTP Callable) ==========
exports.startCallRecording = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId, enabled } = request.data;
        (0, utils_1.logInfo)(`${enabled ? 'Starting' : 'Stopping'} recording for call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        // Verify user is participant
        const isParticipant = (_a = callData.participants) === null || _a === void 0 ? void 0 : _a.some((p) => p.userId === uid);
        if (!isParticipant) {
            throw new Error('Not authorized');
        }
        await callRef.update({
            recordingEnabled: enabled,
            recordingStartedAt: enabled ? utils_1.FieldValue.serverTimestamp() : null,
            recordingStartedBy: enabled ? uid : null,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // In production, this would trigger Agora Cloud Recording API
        // For now, we'll just track the state
        return { success: true, recording: enabled };
    }
    catch (error) {
        (0, utils_1.logError)('Error managing call recording:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 7. MUTE PARTICIPANT (HTTP Callable) ==========
exports.muteParticipant = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId, participantId, muted } = request.data;
        (0, utils_1.logInfo)(`${muted ? 'Muting' : 'Unmuting'} participant ${participantId} in call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        // Only allow self-mute or host mute in group calls
        if (participantId !== uid && callData.hostId !== uid) {
            throw new Error('Not authorized to mute this participant');
        }
        const participants = callData.participants || [];
        const updatedParticipants = participants.map((p) => {
            if (p.userId === participantId) {
                return Object.assign(Object.assign({}, p), { muted });
            }
            return p;
        });
        await callRef.update({
            participants: updatedParticipants,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error muting participant:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 8. TOGGLE VIDEO (HTTP Callable) ==========
exports.toggleVideo = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId, enabled } = request.data;
        (0, utils_1.logInfo)(`Toggling video to ${enabled} for call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        const participants = callData.participants || [];
        const updatedParticipants = participants.map((p) => {
            if (p.userId === uid) {
                return Object.assign(Object.assign({}, p), { videoEnabled: enabled });
            }
            return p;
        });
        await callRef.update({
            participants: updatedParticipants,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error toggling video:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 9. SHARE SCREEN (HTTP Callable) ==========
exports.shareScreen = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId, enabled } = request.data;
        (0, utils_1.logInfo)(`${enabled ? 'Starting' : 'Stopping'} screen share in call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        await callRef.update({
            screenSharing: enabled,
            screenSharingBy: enabled ? uid : null,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error managing screen share:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 10. SEND CALL REACTION (HTTP Callable) ==========
exports.sendCallReaction = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId, reaction } = request.data;
        (0, utils_1.logInfo)(`Sending reaction ${reaction} in call ${callId}`);
        await utils_1.db.collection('calls').doc(callId).collection('reactions').add({
            userId: uid,
            reaction,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error sending call reaction:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 11. CREATE GROUP CALL (HTTP Callable) ==========
exports.createGroupCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { participantIds, title, scheduledFor } = request.data;
        if (participantIds.length > MAX_GROUP_CALL_PARTICIPANTS) {
            throw new Error(`Maximum ${MAX_GROUP_CALL_PARTICIPANTS} participants allowed`);
        }
        (0, utils_1.logInfo)(`Creating group call with ${participantIds.length} participants`);
        const channelName = `group_${uid}_${Date.now()}`;
        const hostAgoraUid = Math.floor(Math.random() * 1000000);
        const callRef = await utils_1.db.collection('calls').add({
            channelName,
            callType: types_1.CallType.GROUP,
            hostId: uid,
            title: title || 'Group Call',
            status: scheduledFor ? types_1.CallStatus.SCHEDULED : types_1.CallStatus.RINGING,
            scheduledFor: scheduledFor ? admin.firestore.Timestamp.fromDate(new Date(scheduledFor)) : null,
            participants: [
                {
                    userId: uid,
                    agoraUid: hostAgoraUid,
                    role: 'host',
                    joinedAt: scheduledFor ? null : utils_1.FieldValue.serverTimestamp(),
                    leftAt: null,
                },
            ],
            invitedParticipants: participantIds,
            maxParticipants: MAX_GROUP_CALL_PARTICIPANTS,
            recordingEnabled: false,
            startedAt: scheduledFor ? null : utils_1.FieldValue.serverTimestamp(),
            endedAt: null,
            duration: 0,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Send invitations
        for (const participantId of participantIds) {
            await utils_1.db.collection('notifications').add({
                userId: participantId,
                type: scheduledFor ? 'scheduled_group_call' : 'group_call_invitation',
                title: title || 'Group Call Invitation',
                body: `You've been invited to a group call`,
                data: {
                    callId: callRef.id,
                    hostId: uid,
                    scheduledFor,
                },
                read: false,
                sent: false,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        return {
            success: true,
            callId: callRef.id,
            channelName,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error creating group call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 12. JOIN GROUP CALL (HTTP Callable) ==========
exports.joinGroupCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId } = request.data;
        (0, utils_1.logInfo)(`User ${uid} joining group call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        // Check if invited
        const isInvited = ((_a = callData.invitedParticipants) === null || _a === void 0 ? void 0 : _a.includes(uid)) || callData.hostId === uid;
        if (!isInvited) {
            throw new Error('Not invited to this call');
        }
        // Check participant limit
        const currentParticipants = ((_b = callData.participants) === null || _b === void 0 ? void 0 : _b.filter((p) => !p.leftAt)) || [];
        if (currentParticipants.length >= callData.maxParticipants) {
            throw new Error('Call is full');
        }
        const agoraUid = Math.floor(Math.random() * 1000000);
        await callRef.update({
            status: types_1.CallStatus.ACTIVE,
            startedAt: callData.startedAt || utils_1.FieldValue.serverTimestamp(),
            participants: utils_1.FieldValue.arrayUnion({
                userId: uid,
                agoraUid,
                role: 'participant',
                joinedAt: utils_1.FieldValue.serverTimestamp(),
                leftAt: null,
            }),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            channelName: callData.channelName,
            agoraUid,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error joining group call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 13. INVITE TO GROUP CALL (HTTP Callable) ==========
exports.inviteToGroupCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId, participantIds } = request.data;
        (0, utils_1.logInfo)(`Inviting ${participantIds.length} users to call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        // Only host can invite
        if (callData.hostId !== uid) {
            throw new Error('Only host can invite participants');
        }
        await callRef.update({
            invitedParticipants: utils_1.FieldValue.arrayUnion(...participantIds),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Send invitations
        for (const participantId of participantIds) {
            await utils_1.db.collection('notifications').add({
                userId: participantId,
                type: 'group_call_invitation',
                title: callData.title || 'Group Call Invitation',
                body: `You've been invited to join a group call`,
                data: {
                    callId,
                    hostId: uid,
                },
                read: false,
                sent: false,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error inviting to group call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 14. REMOVE FROM GROUP CALL (HTTP Callable) ==========
exports.removeFromGroupCall = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId, participantId } = request.data;
        (0, utils_1.logInfo)(`Removing participant ${participantId} from call ${callId}`);
        const callRef = utils_1.db.collection('calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        // Only host can remove
        if (callData.hostId !== uid) {
            throw new Error('Only host can remove participants');
        }
        const participants = callData.participants || [];
        const updatedParticipants = participants.map((p) => {
            if (p.userId === participantId) {
                return Object.assign(Object.assign({}, p), { leftAt: utils_1.FieldValue.serverTimestamp(), removed: true });
            }
            return p;
        });
        await callRef.update({
            participants: updatedParticipants,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Notify removed user
        await utils_1.db.collection('notifications').add({
            userId: participantId,
            type: 'removed_from_call',
            title: 'Removed from Call',
            body: 'You were removed from the group call',
            data: { callId },
            read: false,
            sent: false,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error removing from group call:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 15. GET CALL HISTORY (HTTP Callable) ==========
exports.getCallHistory = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { limit = 50, startAfter } = request.data;
        (0, utils_1.logInfo)(`Fetching call history for user ${uid}`);
        let query = utils_1.db
            .collection('calls')
            .where('participants', 'array-contains', { userId: uid })
            .orderBy('createdAt', 'desc')
            .limit(limit);
        if (startAfter) {
            const startDoc = await utils_1.db.collection('calls').doc(startAfter).get();
            if (startDoc.exists) {
                query = query.startAfter(startDoc);
            }
        }
        const snapshot = await query.get();
        const calls = snapshot.docs.map(doc => (Object.assign({ id: doc.id }, doc.data())));
        return {
            success: true,
            calls,
            hasMore: snapshot.size === limit,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching call history:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 16. GET CALL ANALYTICS (HTTP Callable) ==========
exports.getCallAnalytics = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { callId } = request.data;
        (0, utils_1.logInfo)(`Fetching call analytics for ${callId}`);
        const callDoc = await utils_1.db.collection('calls').doc(callId).get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        // Verify user was participant
        const isParticipant = (_a = callData.participants) === null || _a === void 0 ? void 0 : _a.some((p) => p.userId === uid);
        if (!isParticipant) {
            throw new Error('Not authorized');
        }
        // Calculate analytics
        const participants = callData.participants || [];
        const participantCount = participants.length;
        const avgDuration = participants.reduce((sum, p) => {
            if (p.joinedAt && p.leftAt) {
                const duration = p.leftAt.toMillis() - p.joinedAt.toMillis();
                return sum + duration;
            }
            return sum;
        }, 0) / participantCount;
        return {
            success: true,
            analytics: {
                callId,
                duration: callData.duration || 0,
                participantCount,
                avgParticipantDuration: Math.floor(avgDuration / 1000),
                recordingEnabled: callData.recordingEnabled || false,
                callType: callData.callType,
                status: callData.status,
            },
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching call analytics:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 17. ON CALL STARTED (Firestore Trigger) ==========
exports.onCallStarted = (0, firestore_1.onDocumentUpdated)({
    document: 'calls/{callId}',
    memory: '256MiB',
}, async (event) => {
    var _a, _b;
    try {
        const beforeData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
        const afterData = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
        if (!beforeData || !afterData)
            return;
        // Check if call just started
        if (beforeData.status === types_1.CallStatus.RINGING && afterData.status === types_1.CallStatus.ACTIVE) {
            (0, utils_1.logInfo)(`Call started: ${event.params.callId}`);
            // Grant XP for video call
            const participants = afterData.participants || [];
            for (const participant of participants) {
                // This would trigger grantXP from gamification service
                // For now, just log
                (0, utils_1.logInfo)(`Granting XP to ${participant.userId} for starting call`);
            }
        }
    }
    catch (error) {
        (0, utils_1.logError)('Error in onCallStarted trigger:', error);
    }
});
// ========== 18. ON CALL ENDED (Firestore Trigger) ==========
exports.onCallEnded = (0, firestore_1.onDocumentUpdated)({
    document: 'calls/{callId}',
    memory: '256MiB',
}, async (event) => {
    var _a, _b;
    try {
        const beforeData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
        const afterData = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
        if (!beforeData || !afterData)
            return;
        // Check if call just ended
        if (beforeData.status === types_1.CallStatus.ACTIVE && afterData.status === types_1.CallStatus.ENDED) {
            const callId = event.params.callId;
            (0, utils_1.logInfo)(`Call ended: ${callId}`);
            // Update call statistics
            const participants = afterData.participants || [];
            for (const participant of participants) {
                if (participant.joinedAt && participant.leftAt) {
                    const userStatsRef = utils_1.db.collection('users').doc(participant.userId);
                    await userStatsRef.update({
                        'stats.totalCalls': utils_1.FieldValue.increment(1),
                        'stats.totalCallMinutes': utils_1.FieldValue.increment(Math.floor(afterData.duration / 60)),
                        updatedAt: utils_1.FieldValue.serverTimestamp(),
                    });
                }
            }
            // Process recording if enabled
            if (afterData.recordingEnabled) {
                (0, utils_1.logInfo)(`Processing recording for call ${callId}`);
                // In production, this would download from Agora and store in Cloud Storage
            }
        }
    }
    catch (error) {
        (0, utils_1.logError)('Error in onCallEnded trigger:', error);
    }
});
// ========== 19. CLEANUP MISSED CALLS (Scheduled - Every 5 minutes) ==========
exports.cleanupMissedCalls = (0, scheduler_1.onSchedule)({
    schedule: '*/5 * * * *', // Every 5 minutes
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async () => {
    (0, utils_1.logInfo)('Cleaning up missed calls');
    try {
        // Find calls that have been ringing for > 60 seconds
        const oneMinuteAgo = new Date(Date.now() - 60 * 1000);
        const cutoffTimestamp = admin.firestore.Timestamp.fromDate(oneMinuteAgo);
        const snapshot = await utils_1.db
            .collection('calls')
            .where('status', '==', types_1.CallStatus.RINGING)
            .where('createdAt', '<', cutoffTimestamp)
            .get();
        if (snapshot.empty) {
            return;
        }
        const batch = utils_1.db.batch();
        for (const doc of snapshot.docs) {
            batch.update(doc.ref, {
                status: types_1.CallStatus.MISSED,
                endedAt: utils_1.FieldValue.serverTimestamp(),
            });
            const callData = doc.data();
            // Notify caller
            await utils_1.db.collection('notifications').add({
                userId: callData.callerId,
                type: 'call_missed',
                title: 'Call Not Answered',
                body: 'Your call was not answered',
                data: { callId: doc.id },
                read: false,
                sent: false,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        await batch.commit();
        (0, utils_1.logInfo)(`Cleaned up ${snapshot.size} missed calls`);
    }
    catch (error) {
        (0, utils_1.logError)('Error cleaning up missed calls:', error);
    }
});
// ========== 20. CLEANUP ABANDONED CALLS (Scheduled - Hourly) ==========
exports.cleanupAbandonedCalls = (0, scheduler_1.onSchedule)({
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
}, async () => {
    (0, utils_1.logInfo)('Cleaning up abandoned calls');
    try {
        // Find active calls older than 4 hours (max duration)
        const fourHoursAgo = new Date(Date.now() - MAX_CALL_DURATION * 1000);
        const cutoffTimestamp = admin.firestore.Timestamp.fromDate(fourHoursAgo);
        const snapshot = await utils_1.db
            .collection('calls')
            .where('status', '==', types_1.CallStatus.ACTIVE)
            .where('startedAt', '<', cutoffTimestamp)
            .get();
        if (snapshot.empty) {
            return;
        }
        const batch = utils_1.db.batch();
        for (const doc of snapshot.docs) {
            const callData = doc.data();
            const duration = callData.startedAt ?
                Math.floor((Date.now() - callData.startedAt.toMillis()) / 1000) : 0;
            batch.update(doc.ref, {
                status: types_1.CallStatus.ENDED,
                endedAt: utils_1.FieldValue.serverTimestamp(),
                duration,
                abandoned: true,
            });
        }
        await batch.commit();
        (0, utils_1.logInfo)(`Cleaned up ${snapshot.size} abandoned calls`);
    }
    catch (error) {
        (0, utils_1.logError)('Error cleaning up abandoned calls:', error);
    }
});
// ========== 21. ARCHIVE OLD CALL RECORDS (Scheduled - Daily) ==========
exports.archiveOldCallRecords = (0, scheduler_1.onSchedule)({
    schedule: '0 5 * * *', // Daily at 5 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
}, async () => {
    (0, utils_1.logInfo)('Archiving old call records');
    try {
        // Archive calls older than 90 days
        const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
        const cutoffTimestamp = admin.firestore.Timestamp.fromDate(ninetyDaysAgo);
        const snapshot = await utils_1.db
            .collection('calls')
            .where('endedAt', '<', cutoffTimestamp)
            .limit(500)
            .get();
        if (snapshot.empty) {
            (0, utils_1.logInfo)('No old calls to archive');
            return;
        }
        let archivedCount = 0;
        for (const doc of snapshot.docs) {
            const callData = doc.data();
            // Move to archive collection
            await utils_1.db.collection('call_archives').doc(doc.id).set(Object.assign(Object.assign({}, callData), { archivedAt: utils_1.FieldValue.serverTimestamp() }));
            // Delete from main collection
            await doc.ref.delete();
            archivedCount++;
        }
        (0, utils_1.logInfo)(`Archived ${archivedCount} old call records`);
    }
    catch (error) {
        (0, utils_1.logError)('Error archiving old call records:', error);
    }
});
//# sourceMappingURL=index.js.map