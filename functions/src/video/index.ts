/**
 * Video Calling Service
 * 21 Cloud Functions for managing video calls using Agora.io
 */

import { onCall } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { verifyAuth, handleError, logInfo, logError, db, FieldValue } from '../shared/utils';
import * as admin from 'firebase-admin';
import { RtcTokenBuilder, RtcRole } from 'agora-access-token';
import { CallStatus, CallType } from '../shared/types';

// Agora Configuration (these should be in environment variables)
const AGORA_APP_ID = process.env.AGORA_APP_ID || '';
const AGORA_APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE || '';

// Call Configuration
const TOKEN_EXPIRATION_TIME = 3600; // 1 hour
const MAX_CALL_DURATION = 4 * 60 * 60; // 4 hours
const MAX_GROUP_CALL_PARTICIPANTS = 50;
const RECORDING_BUCKET = process.env.RECORDING_BUCKET || 'call-recordings';

// Interfaces
interface GenerateTokenRequest {
  channelName: string;
  uid: number;
  role?: 'publisher' | 'subscriber';
}

interface InitiateCallRequest {
  recipientId: string;
  callType: CallType;
  videoEnabled?: boolean;
}

interface JoinCallRequest {
  callId: string;
}

interface EndCallRequest {
  callId: string;
}

interface RecordCallRequest {
  callId: string;
  enabled: boolean;
}

interface MuteParticipantRequest {
  callId: string;
  participantId: string;
  muted: boolean;
}

interface ToggleVideoRequest {
  callId: string;
  enabled: boolean;
}

interface ShareScreenRequest {
  callId: string;
  enabled: boolean;
}

interface SendCallReactionRequest {
  callId: string;
  reaction: string;
}

interface CreateGroupCallRequest {
  participantIds: string[];
  title?: string;
  scheduledFor?: string;
}

interface InviteToGroupCallRequest {
  callId: string;
  participantIds: string[];
}

interface RemoveFromGroupCallRequest {
  callId: string;
  participantId: string;
}

interface GetCallHistoryRequest {
  limit?: number;
  startAfter?: string;
}

interface GetCallAnalyticsRequest {
  callId: string;
}

// ========== 1. GENERATE AGORA TOKEN (HTTP Callable) ==========

export const generateAgoraToken = onCall<GenerateTokenRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { channelName, uid: agoraUid, role = 'publisher' } = request.data;

      if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
        throw new Error('Agora credentials not configured');
      }

      logInfo(`Generating Agora token for user ${uid}, channel: ${channelName}`);

      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + TOKEN_EXPIRATION_TIME;

      const tokenRole = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

      const token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName,
        agoraUid,
        tokenRole,
        privilegeExpiredTs
      );

      return {
        success: true,
        token,
        appId: AGORA_APP_ID,
        channelName,
        uid: agoraUid,
        expiresAt: privilegeExpiredTs,
      };
    } catch (error) {
      logError('Error generating Agora token:', error);
      throw handleError(error);
    }
  }
);

// ========== 2. INITIATE CALL (HTTP Callable) ==========

export const initiateCall = onCall<InitiateCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { recipientId, callType, videoEnabled = true } = request.data;

      logInfo(`Initiating call from ${uid} to ${recipientId}`);

      // Check if recipient exists
      const recipientDoc = await db.collection('users').doc(recipientId).get();
      if (!recipientDoc.exists) {
        throw new Error('Recipient not found');
      }

      // Check if recipient is blocked or has blocked caller
      const blockSnapshot = await db
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
      const callRef = await db.collection('calls').add({
        channelName,
        callerId: uid,
        recipientId,
        callType,
        videoEnabled,
        status: CallStatus.RINGING,
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
        createdAt: FieldValue.serverTimestamp(),
      });

      // Send notification to recipient
      await db.collection('notifications').add({
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
        createdAt: FieldValue.serverTimestamp(),
      });

      logInfo(`Call initiated: ${callRef.id}`);

      return {
        success: true,
        callId: callRef.id,
        channelName,
      };
    } catch (error) {
      logError('Error initiating call:', error);
      throw handleError(error);
    }
  }
);

// ========== 3. ANSWER CALL (HTTP Callable) ==========

export const answerCall = onCall<JoinCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId } = request.data;

      logInfo(`User ${uid} answering call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      if (callData.recipientId !== uid) {
        throw new Error('Not authorized to answer this call');
      }

      if (callData.status !== CallStatus.RINGING) {
        throw new Error('Call is not in ringing state');
      }

      const agoraUid = Math.floor(Math.random() * 1000000);

      // Update call status
      await callRef.update({
        status: CallStatus.ACTIVE,
        startedAt: FieldValue.serverTimestamp(),
        participants: FieldValue.arrayUnion({
          userId: uid,
          agoraUid,
          role: 'recipient',
          joinedAt: FieldValue.serverTimestamp(),
          leftAt: null,
        }),
        updatedAt: FieldValue.serverTimestamp(),
      });

      logInfo(`Call answered: ${callId}`);

      return {
        success: true,
        callId,
        channelName: callData.channelName,
        agoraUid,
      };
    } catch (error) {
      logError('Error answering call:', error);
      throw handleError(error);
    }
  }
);

// ========== 4. REJECT CALL (HTTP Callable) ==========

export const rejectCall = onCall<JoinCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId } = request.data;

      logInfo(`User ${uid} rejecting call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      if (callData.recipientId !== uid) {
        throw new Error('Not authorized to reject this call');
      }

      await callRef.update({
        status: CallStatus.REJECTED,
        endedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Notify caller
      await db.collection('notifications').add({
        userId: callData.callerId,
        type: 'call_rejected',
        title: 'Call Rejected',
        body: 'Your call was rejected',
        data: { callId },
        read: false,
        sent: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error rejecting call:', error);
      throw handleError(error);
    }
  }
);

// ========== 5. END CALL (HTTP Callable) ==========

export const endCall = onCall<EndCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId } = request.data;

      logInfo(`User ${uid} ending call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      // Update participant's left time
      const participants = callData.participants || [];
      const updatedParticipants = participants.map((p: any) => {
        if (p.userId === uid && !p.leftAt) {
          return { ...p, leftAt: FieldValue.serverTimestamp() };
        }
        return p;
      });

      // Check if all participants have left
      const allLeft = updatedParticipants.every((p: any) => p.leftAt !== null);

      const updateData: any = {
        participants: updatedParticipants,
        updatedAt: FieldValue.serverTimestamp(),
      };

      if (allLeft) {
        updateData.status = CallStatus.ENDED;
        updateData.endedAt = FieldValue.serverTimestamp();

        // Calculate duration
        if (callData.startedAt) {
          const duration = Math.floor((Date.now() - callData.startedAt.toMillis()) / 1000);
          updateData.duration = duration;
        }
      }

      await callRef.update(updateData);

      logInfo(`Call ended: ${callId}`);

      return { success: true, allEnded: allLeft };
    } catch (error) {
      logError('Error ending call:', error);
      throw handleError(error);
    }
  }
);

// ========== 6. START CALL RECORDING (HTTP Callable) ==========

export const startCallRecording = onCall<RecordCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId, enabled } = request.data;

      logInfo(`${enabled ? 'Starting' : 'Stopping'} recording for call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      // Verify user is participant
      const isParticipant = callData.participants?.some((p: any) => p.userId === uid);
      if (!isParticipant) {
        throw new Error('Not authorized');
      }

      await callRef.update({
        recordingEnabled: enabled,
        recordingStartedAt: enabled ? FieldValue.serverTimestamp() : null,
        recordingStartedBy: enabled ? uid : null,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // In production, this would trigger Agora Cloud Recording API
      // For now, we'll just track the state

      return { success: true, recording: enabled };
    } catch (error) {
      logError('Error managing call recording:', error);
      throw handleError(error);
    }
  }
);

// ========== 7. MUTE PARTICIPANT (HTTP Callable) ==========

export const muteParticipant = onCall<MuteParticipantRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId, participantId, muted } = request.data;

      logInfo(`${muted ? 'Muting' : 'Unmuting'} participant ${participantId} in call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      // Only allow self-mute or host mute in group calls
      if (participantId !== uid && callData.hostId !== uid) {
        throw new Error('Not authorized to mute this participant');
      }

      const participants = callData.participants || [];
      const updatedParticipants = participants.map((p: any) => {
        if (p.userId === participantId) {
          return { ...p, muted };
        }
        return p;
      });

      await callRef.update({
        participants: updatedParticipants,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error muting participant:', error);
      throw handleError(error);
    }
  }
);

// ========== 8. TOGGLE VIDEO (HTTP Callable) ==========

export const toggleVideo = onCall<ToggleVideoRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId, enabled } = request.data;

      logInfo(`Toggling video to ${enabled} for call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;
      const participants = callData.participants || [];

      const updatedParticipants = participants.map((p: any) => {
        if (p.userId === uid) {
          return { ...p, videoEnabled: enabled };
        }
        return p;
      });

      await callRef.update({
        participants: updatedParticipants,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error toggling video:', error);
      throw handleError(error);
    }
  }
);

// ========== 9. SHARE SCREEN (HTTP Callable) ==========

export const shareScreen = onCall<ShareScreenRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId, enabled } = request.data;

      logInfo(`${enabled ? 'Starting' : 'Stopping'} screen share in call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      await callRef.update({
        screenSharing: enabled,
        screenSharingBy: enabled ? uid : null,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error managing screen share:', error);
      throw handleError(error);
    }
  }
);

// ========== 10. SEND CALL REACTION (HTTP Callable) ==========

export const sendCallReaction = onCall<SendCallReactionRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId, reaction } = request.data;

      logInfo(`Sending reaction ${reaction} in call ${callId}`);

      await db.collection('calls').doc(callId).collection('reactions').add({
        userId: uid,
        reaction,
        timestamp: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error sending call reaction:', error);
      throw handleError(error);
    }
  }
);

// ========== 11. CREATE GROUP CALL (HTTP Callable) ==========

export const createGroupCall = onCall<CreateGroupCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { participantIds, title, scheduledFor } = request.data;

      if (participantIds.length > MAX_GROUP_CALL_PARTICIPANTS) {
        throw new Error(`Maximum ${MAX_GROUP_CALL_PARTICIPANTS} participants allowed`);
      }

      logInfo(`Creating group call with ${participantIds.length} participants`);

      const channelName = `group_${uid}_${Date.now()}`;
      const hostAgoraUid = Math.floor(Math.random() * 1000000);

      const callRef = await db.collection('calls').add({
        channelName,
        callType: CallType.GROUP,
        hostId: uid,
        title: title || 'Group Call',
        status: scheduledFor ? CallStatus.SCHEDULED : CallStatus.RINGING,
        scheduledFor: scheduledFor ? admin.firestore.Timestamp.fromDate(new Date(scheduledFor)) : null,
        participants: [
          {
            userId: uid,
            agoraUid: hostAgoraUid,
            role: 'host',
            joinedAt: scheduledFor ? null : FieldValue.serverTimestamp(),
            leftAt: null,
          },
        ],
        invitedParticipants: participantIds,
        maxParticipants: MAX_GROUP_CALL_PARTICIPANTS,
        recordingEnabled: false,
        startedAt: scheduledFor ? null : FieldValue.serverTimestamp(),
        endedAt: null,
        duration: 0,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Send invitations
      for (const participantId of participantIds) {
        await db.collection('notifications').add({
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
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      return {
        success: true,
        callId: callRef.id,
        channelName,
      };
    } catch (error) {
      logError('Error creating group call:', error);
      throw handleError(error);
    }
  }
);

// ========== 12. JOIN GROUP CALL (HTTP Callable) ==========

export const joinGroupCall = onCall<JoinCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId } = request.data;

      logInfo(`User ${uid} joining group call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      // Check if invited
      const isInvited = callData.invitedParticipants?.includes(uid) || callData.hostId === uid;
      if (!isInvited) {
        throw new Error('Not invited to this call');
      }

      // Check participant limit
      const currentParticipants = callData.participants?.filter((p: any) => !p.leftAt) || [];
      if (currentParticipants.length >= callData.maxParticipants) {
        throw new Error('Call is full');
      }

      const agoraUid = Math.floor(Math.random() * 1000000);

      await callRef.update({
        status: CallStatus.ACTIVE,
        startedAt: callData.startedAt || FieldValue.serverTimestamp(),
        participants: FieldValue.arrayUnion({
          userId: uid,
          agoraUid,
          role: 'participant',
          joinedAt: FieldValue.serverTimestamp(),
          leftAt: null,
        }),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        channelName: callData.channelName,
        agoraUid,
      };
    } catch (error) {
      logError('Error joining group call:', error);
      throw handleError(error);
    }
  }
);

// ========== 13. INVITE TO GROUP CALL (HTTP Callable) ==========

export const inviteToGroupCall = onCall<InviteToGroupCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId, participantIds } = request.data;

      logInfo(`Inviting ${participantIds.length} users to call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      // Only host can invite
      if (callData.hostId !== uid) {
        throw new Error('Only host can invite participants');
      }

      await callRef.update({
        invitedParticipants: FieldValue.arrayUnion(...participantIds),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Send invitations
      for (const participantId of participantIds) {
        await db.collection('notifications').add({
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
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      return { success: true };
    } catch (error) {
      logError('Error inviting to group call:', error);
      throw handleError(error);
    }
  }
);

// ========== 14. REMOVE FROM GROUP CALL (HTTP Callable) ==========

export const removeFromGroupCall = onCall<RemoveFromGroupCallRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId, participantId } = request.data;

      logInfo(`Removing participant ${participantId} from call ${callId}`);

      const callRef = db.collection('calls').doc(callId);
      const callDoc = await callRef.get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      // Only host can remove
      if (callData.hostId !== uid) {
        throw new Error('Only host can remove participants');
      }

      const participants = callData.participants || [];
      const updatedParticipants = participants.map((p: any) => {
        if (p.userId === participantId) {
          return { ...p, leftAt: FieldValue.serverTimestamp(), removed: true };
        }
        return p;
      });

      await callRef.update({
        participants: updatedParticipants,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Notify removed user
      await db.collection('notifications').add({
        userId: participantId,
        type: 'removed_from_call',
        title: 'Removed from Call',
        body: 'You were removed from the group call',
        data: { callId },
        read: false,
        sent: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error removing from group call:', error);
      throw handleError(error);
    }
  }
);

// ========== 15. GET CALL HISTORY (HTTP Callable) ==========

export const getCallHistory = onCall<GetCallHistoryRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { limit = 50, startAfter } = request.data;

      logInfo(`Fetching call history for user ${uid}`);

      let query = db
        .collection('calls')
        .where('participants', 'array-contains', { userId: uid })
        .orderBy('createdAt', 'desc')
        .limit(limit);

      if (startAfter) {
        const startDoc = await db.collection('calls').doc(startAfter).get();
        if (startDoc.exists) {
          query = query.startAfter(startDoc);
        }
      }

      const snapshot = await query.get();

      const calls = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));

      return {
        success: true,
        calls,
        hasMore: snapshot.size === limit,
      };
    } catch (error) {
      logError('Error fetching call history:', error);
      throw handleError(error);
    }
  }
);

// ========== 16. GET CALL ANALYTICS (HTTP Callable) ==========

export const getCallAnalytics = onCall<GetCallAnalyticsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { callId } = request.data;

      logInfo(`Fetching call analytics for ${callId}`);

      const callDoc = await db.collection('calls').doc(callId).get();

      if (!callDoc.exists) {
        throw new Error('Call not found');
      }

      const callData = callDoc.data()!;

      // Verify user was participant
      const isParticipant = callData.participants?.some((p: any) => p.userId === uid);
      if (!isParticipant) {
        throw new Error('Not authorized');
      }

      // Calculate analytics
      const participants = callData.participants || [];
      const participantCount = participants.length;
      const avgDuration = participants.reduce((sum: number, p: any) => {
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
    } catch (error) {
      logError('Error fetching call analytics:', error);
      throw handleError(error);
    }
  }
);

// ========== 17. ON CALL STARTED (Firestore Trigger) ==========

export const onCallStarted = onDocumentUpdated(
  {
    document: 'calls/{callId}',
    memory: '256MiB',
  },
  async (event) => {
    try {
      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();

      if (!beforeData || !afterData) return;

      // Check if call just started
      if (beforeData.status === CallStatus.RINGING && afterData.status === CallStatus.ACTIVE) {
        logInfo(`Call started: ${event.params.callId}`);

        // Grant XP for video call
        const participants = afterData.participants || [];
        for (const participant of participants) {
          // This would trigger grantXP from gamification service
          // For now, just log
          logInfo(`Granting XP to ${participant.userId} for starting call`);
        }
      }
    } catch (error) {
      logError('Error in onCallStarted trigger:', error);
    }
  }
);

// ========== 18. ON CALL ENDED (Firestore Trigger) ==========

export const onCallEnded = onDocumentUpdated(
  {
    document: 'calls/{callId}',
    memory: '256MiB',
  },
  async (event) => {
    try {
      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();

      if (!beforeData || !afterData) return;

      // Check if call just ended
      if (beforeData.status === CallStatus.ACTIVE && afterData.status === CallStatus.ENDED) {
        const callId = event.params.callId;
        logInfo(`Call ended: ${callId}`);

        // Update call statistics
        const participants = afterData.participants || [];
        for (const participant of participants) {
          if (participant.joinedAt && participant.leftAt) {
            const userStatsRef = db.collection('users').doc(participant.userId);
            await userStatsRef.update({
              'stats.totalCalls': FieldValue.increment(1),
              'stats.totalCallMinutes': FieldValue.increment(Math.floor(afterData.duration / 60)),
              updatedAt: FieldValue.serverTimestamp(),
            });
          }
        }

        // Process recording if enabled
        if (afterData.recordingEnabled) {
          logInfo(`Processing recording for call ${callId}`);
          // In production, this would download from Agora and store in Cloud Storage
        }
      }
    } catch (error) {
      logError('Error in onCallEnded trigger:', error);
    }
  }
);

// ========== 19. CLEANUP MISSED CALLS (Scheduled - Every 5 minutes) ==========

export const cleanupMissedCalls = onSchedule(
  {
    schedule: '*/5 * * * *', // Every 5 minutes
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async () => {
    logInfo('Cleaning up missed calls');

    try {
      // Find calls that have been ringing for > 60 seconds
      const oneMinuteAgo = new Date(Date.now() - 60 * 1000);
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(oneMinuteAgo);

      const snapshot = await db
        .collection('calls')
        .where('status', '==', CallStatus.RINGING)
        .where('createdAt', '<', cutoffTimestamp)
        .get();

      if (snapshot.empty) {
        return;
      }

      const batch = db.batch();

      for (const doc of snapshot.docs) {
        batch.update(doc.ref, {
          status: CallStatus.MISSED,
          endedAt: FieldValue.serverTimestamp(),
        });

        const callData = doc.data();

        // Notify caller
        await db.collection('notifications').add({
          userId: callData.callerId,
          type: 'call_missed',
          title: 'Call Not Answered',
          body: 'Your call was not answered',
          data: { callId: doc.id },
          read: false,
          sent: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      logInfo(`Cleaned up ${snapshot.size} missed calls`);
    } catch (error) {
      logError('Error cleaning up missed calls:', error);
    }
  }
);

// ========== 20. CLEANUP ABANDONED CALLS (Scheduled - Hourly) ==========

export const cleanupAbandonedCalls = onSchedule(
  {
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Cleaning up abandoned calls');

    try {
      // Find active calls older than 4 hours (max duration)
      const fourHoursAgo = new Date(Date.now() - MAX_CALL_DURATION * 1000);
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(fourHoursAgo);

      const snapshot = await db
        .collection('calls')
        .where('status', '==', CallStatus.ACTIVE)
        .where('startedAt', '<', cutoffTimestamp)
        .get();

      if (snapshot.empty) {
        return;
      }

      const batch = db.batch();

      for (const doc of snapshot.docs) {
        const callData = doc.data();
        const duration = callData.startedAt ?
          Math.floor((Date.now() - callData.startedAt.toMillis()) / 1000) : 0;

        batch.update(doc.ref, {
          status: CallStatus.ENDED,
          endedAt: FieldValue.serverTimestamp(),
          duration,
          abandoned: true,
        });
      }

      await batch.commit();

      logInfo(`Cleaned up ${snapshot.size} abandoned calls`);
    } catch (error) {
      logError('Error cleaning up abandoned calls:', error);
    }
  }
);

// ========== 21. ARCHIVE OLD CALL RECORDS (Scheduled - Daily) ==========

export const archiveOldCallRecords = onSchedule(
  {
    schedule: '0 5 * * *', // Daily at 5 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Archiving old call records');

    try {
      // Archive calls older than 90 days
      const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(ninetyDaysAgo);

      const snapshot = await db
        .collection('calls')
        .where('endedAt', '<', cutoffTimestamp)
        .limit(500)
        .get();

      if (snapshot.empty) {
        logInfo('No old calls to archive');
        return;
      }

      let archivedCount = 0;

      for (const doc of snapshot.docs) {
        const callData = doc.data();

        // Move to archive collection
        await db.collection('call_archives').doc(doc.id).set({
          ...callData,
          archivedAt: FieldValue.serverTimestamp(),
        });

        // Delete from main collection
        await doc.ref.delete();
        archivedCount++;
      }

      logInfo(`Archived ${archivedCount} old call records`);
    } catch (error) {
      logError('Error archiving old call records:', error);
    }
  }
);
