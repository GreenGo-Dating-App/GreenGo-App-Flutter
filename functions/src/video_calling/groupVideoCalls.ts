/**
 * Group Video Call Cloud Functions
 * Points 141-145: Group calls, breakout rooms
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();

/**
 * Create Group Video Call
 * Point 141: Up to 6 participants
 */
export const createGroupVideoCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const hostId = context.auth.uid;
  const { participantIds, title, maxParticipants } = data;

  try {
    // Validate participant count (Point 141: max 6)
    const max = maxParticipants || 6;
    if (participantIds.length > max - 1) { // -1 for host
      throw new Error(`Maximum ${max} participants allowed`);
    }

    // Verify all participants exist
    const participantDocs = await Promise.all(
      participantIds.map((id: string) => firestore.collection('users').doc(id).get())
    );

    if (participantDocs.some(doc => !doc.exists)) {
      throw new Error('One or more participants not found');
    }

    // Create group call
    const callRef = firestore.collection('group_video_calls').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const participants = [
      {
        userId: hostId,
        role: 'host',
        joinedAt: now,
        leftAt: null,
        isAudioMuted: false,
        isVideoMuted: false,
        isSpeaking: false,
        networkQuality: 'excellent',
      },
      ...participantIds.map((id: string) => ({
        userId: id,
        role: 'participant',
        joinedAt: null,
        leftAt: null,
        isAudioMuted: false,
        isVideoMuted: false,
        isSpeaking: false,
        networkQuality: 'excellent',
      })),
    ];

    await callRef.set({
      callId: callRef.id,
      hostId,
      title: title || 'Group Video Call',
      participants,
      maxParticipants: max,
      status: 'waiting',
      createdAt: now,
      startedAt: null,
      endedAt: null,
      duration: 0,
      agoraChannelName: `greengo_group_${callRef.id}`,
      layout: 'grid', // Point 144: grid, speaker, presentation
      speakerUserId: null,
      recordingEnabled: false,
      screenSharingUserId: null,
      breakoutRooms: [],
    });

    // Send notifications to all participants
    const notifications = participantIds.map((id: string) =>
      sendGroupCallInvitation(id, {
        callId: callRef.id,
        hostId,
        title: title || 'Group Video Call',
      })
    );

    await Promise.all(notifications);

    console.log(`Group video call created: ${callRef.id}`);
    return {
      success: true,
      callId: callRef.id,
      agoraChannelName: `greengo_group_${callRef.id}`,
    };
  } catch (error: any) {
    console.error('Error creating group video call:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Join Group Video Call
 * Point 142: Participant management
 */
export const joinGroupVideoCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId } = data;

  try {
    const callRef = firestore.collection('group_video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Group call not found');
    }

    const callData = callDoc.data()!;

    // Find participant
    const participantIndex = callData.participants.findIndex(
      (p: any) => p.userId === userId
    );

    if (participantIndex === -1) {
      throw new Error('You are not invited to this call');
    }

    // Check if call is full
    const activeParticipants = callData.participants.filter(
      (p: any) => p.joinedAt !== null && p.leftAt === null
    );

    if (activeParticipants.length >= callData.maxParticipants) {
      throw new Error('Call is full');
    }

    // Update participant status
    const participants = [...callData.participants];
    participants[participantIndex].joinedAt = admin.firestore.FieldValue.serverTimestamp();

    await callRef.update({
      participants,
      status: 'active',
      startedAt: callData.startedAt || admin.firestore.FieldValue.serverTimestamp(),
    });

    // Generate Agora token
    const agoraToken = await generateGroupCallToken(callId, userId);

    console.log(`User ${userId} joined group call: ${callId}`);
    return {
      success: true,
      callId,
      agoraToken,
      agoraChannelName: callData.agoraChannelName,
    };
  } catch (error: any) {
    console.error('Error joining group video call:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Leave Group Video Call
 */
export const leaveGroupVideoCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId } = data;

  try {
    const callRef = firestore.collection('group_video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Group call not found');
    }

    const callData = callDoc.data()!;

    // Find participant
    const participantIndex = callData.participants.findIndex(
      (p: any) => p.userId === userId
    );

    if (participantIndex === -1) {
      throw new Error('You are not in this call');
    }

    // Update participant status
    const participants = [...callData.participants];
    participants[participantIndex].leftAt = admin.firestore.FieldValue.serverTimestamp();

    // Check if host is leaving
    const isHost = callData.hostId === userId;
    const activeParticipants = participants.filter(
      (p: any) => p.joinedAt !== null && p.leftAt === null
    );

    let updates: any = { participants };

    if (isHost && activeParticipants.length === 0) {
      // End call if host leaves and no one else is active
      updates.status = 'ended';
      updates.endedAt = admin.firestore.FieldValue.serverTimestamp();

      if (callData.startedAt) {
        const duration = Math.floor((Date.now() - callData.startedAt.toMillis()) / 1000);
        updates.duration = duration;
      }
    } else if (isHost && activeParticipants.length > 0) {
      // Transfer host to another participant
      const newHost = activeParticipants[0];
      updates.hostId = newHost.userId;

      const newParticipants = [...participants];
      const newHostIndex = newParticipants.findIndex((p: any) => p.userId === newHost.userId);
      newParticipants[newHostIndex].role = 'host';
      updates.participants = newParticipants;
    }

    await callRef.update(updates);

    console.log(`User ${userId} left group call: ${callId}`);
    return { success: true };
  } catch (error: any) {
    console.error('Error leaving group video call:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Manage Group Participant
 * Point 143: Mute, remove, promote to co-host
 */
export const manageGroupParticipant = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId, targetUserId, action } = data;

  try {
    const callRef = firestore.collection('group_video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Group call not found');
    }

    const callData = callDoc.data()!;

    // Verify user is host or co-host
    const userParticipant = callData.participants.find((p: any) => p.userId === userId);
    if (!userParticipant || (userParticipant.role !== 'host' && userParticipant.role !== 'cohost')) {
      throw new Error('Only host or co-host can manage participants');
    }

    // Find target participant
    const targetIndex = callData.participants.findIndex(
      (p: any) => p.userId === targetUserId
    );

    if (targetIndex === -1) {
      throw new Error('Participant not found');
    }

    const participants = [...callData.participants];

    // Perform action (Point 143)
    switch (action) {
      case 'mute_audio':
        participants[targetIndex].isAudioMuted = true;
        break;

      case 'mute_video':
        participants[targetIndex].isVideoMuted = true;
        break;

      case 'promote_cohost':
        if (userParticipant.role !== 'host') {
          throw new Error('Only host can promote to co-host');
        }
        participants[targetIndex].role = 'cohost';
        break;

      case 'demote':
        if (userParticipant.role !== 'host') {
          throw new Error('Only host can demote co-hosts');
        }
        participants[targetIndex].role = 'participant';
        break;

      case 'remove':
        participants[targetIndex].leftAt = admin.firestore.FieldValue.serverTimestamp();

        // Send removal notification
        await sendParticipantRemovedNotification(targetUserId, callId);
        break;

      default:
        throw new Error('Invalid action');
    }

    await callRef.update({ participants });

    console.log(`Participant ${targetUserId} ${action} in call ${callId}`);
    return { success: true };
  } catch (error: any) {
    console.error('Error managing group participant:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Change Group Call Layout
 * Point 144: Grid, speaker, presentation modes
 */
export const changeGroupCallLayout = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId, layout, speakerUserId } = data;

  try {
    const callRef = firestore.collection('group_video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Group call not found');
    }

    const callData = callDoc.data()!;

    // Verify user is in the call
    const participant = callData.participants.find((p: any) => p.userId === userId);
    if (!participant) {
      throw new Error('You are not in this call');
    }

    // Validate layout (Point 144)
    const validLayouts = ['grid', 'speaker', 'presentation'];
    if (!validLayouts.includes(layout)) {
      throw new Error('Invalid layout');
    }

    const updates: any = { layout };

    if (layout === 'speaker' && speakerUserId) {
      updates.speakerUserId = speakerUserId;
    }

    await callRef.update(updates);

    console.log(`Group call layout changed to ${layout}: ${callId}`);
    return { success: true, layout };
  } catch (error: any) {
    console.error('Error changing group call layout:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Create Breakout Room
 * Point 145: Private breakout rooms
 */
export const createBreakoutRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId, participantIds, title } = data;

  try {
    const callRef = firestore.collection('group_video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Group call not found');
    }

    const callData = callDoc.data()!;

    // Verify user is host
    if (callData.hostId !== userId) {
      const userParticipant = callData.participants.find((p: any) => p.userId === userId);
      if (!userParticipant || userParticipant.role !== 'cohost') {
        throw new Error('Only host or co-host can create breakout rooms');
      }
    }

    // Verify all participants are in the main call
    const validParticipants = participantIds.every((id: string) =>
      callData.participants.some((p: any) => p.userId === id)
    );

    if (!validParticipants) {
      throw new Error('All participants must be in the main call');
    }

    // Create breakout room
    const breakoutRoomId = `${callId}_breakout_${Date.now()}`;
    const breakoutRoom = {
      roomId: breakoutRoomId,
      title: title || 'Breakout Room',
      participantIds,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: userId,
      isActive: true,
      agoraChannelName: `greengo_breakout_${breakoutRoomId}`,
    };

    const breakoutRooms = callData.breakoutRooms || [];
    breakoutRooms.push(breakoutRoom);

    await callRef.update({ breakoutRooms });

    // Send notifications to participants
    const notifications = participantIds.map((id: string) =>
      sendBreakoutRoomInvitation(id, {
        callId,
        roomId: breakoutRoomId,
        title: breakoutRoom.title,
      })
    );

    await Promise.all(notifications);

    console.log(`Breakout room created: ${breakoutRoomId}`);
    return {
      success: true,
      roomId: breakoutRoomId,
      agoraChannelName: breakoutRoom.agoraChannelName,
    };
  } catch (error: any) {
    console.error('Error creating breakout room:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Join Breakout Room
 * Point 145: Move to breakout room
 */
export const joinBreakoutRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId, roomId } = data;

  try {
    const callRef = firestore.collection('group_video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Group call not found');
    }

    const callData = callDoc.data()!;

    // Find breakout room
    const breakoutRoom = callData.breakoutRooms?.find((room: any) => room.roomId === roomId);

    if (!breakoutRoom) {
      throw new Error('Breakout room not found');
    }

    if (!breakoutRoom.isActive) {
      throw new Error('Breakout room is closed');
    }

    // Verify user is invited
    if (!breakoutRoom.participantIds.includes(userId)) {
      throw new Error('You are not invited to this breakout room');
    }

    // Generate Agora token for breakout room
    const agoraToken = await generateGroupCallToken(roomId, userId);

    console.log(`User ${userId} joined breakout room: ${roomId}`);
    return {
      success: true,
      roomId,
      agoraToken,
      agoraChannelName: breakoutRoom.agoraChannelName,
    };
  } catch (error: any) {
    console.error('Error joining breakout room:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Close Breakout Room
 * Point 145: Return participants to main call
 */
export const closeBreakoutRoom = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId, roomId } = data;

  try {
    const callRef = firestore.collection('group_video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Group call not found');
    }

    const callData = callDoc.data()!;

    // Verify user is host or co-host
    if (callData.hostId !== userId) {
      const userParticipant = callData.participants.find((p: any) => p.userId === userId);
      if (!userParticipant || userParticipant.role !== 'cohost') {
        throw new Error('Only host or co-host can close breakout rooms');
      }
    }

    // Find and close breakout room
    const breakoutRooms = callData.breakoutRooms || [];
    const roomIndex = breakoutRooms.findIndex((room: any) => room.roomId === roomId);

    if (roomIndex === -1) {
      throw new Error('Breakout room not found');
    }

    breakoutRooms[roomIndex].isActive = false;
    breakoutRooms[roomIndex].closedAt = admin.firestore.FieldValue.serverTimestamp();

    await callRef.update({ breakoutRooms });

    // Notify participants to return to main call
    const room = breakoutRooms[roomIndex];
    const notifications = room.participantIds.map((id: string) =>
      sendBreakoutRoomClosed(id, { callId, roomId })
    );

    await Promise.all(notifications);

    console.log(`Breakout room closed: ${roomId}`);
    return { success: true };
  } catch (error: any) {
    console.error('Error closing breakout room:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Helper Functions
 */

async function generateGroupCallToken(channelName: string, userId: string): Promise<string> {
  // In production, use actual Agora token generation
  return `agora_group_token_${channelName}_${userId}`;
}

async function sendGroupCallInvitation(
  userId: string,
  data: { callId: string; hostId: string; title: string }
): Promise<void> {
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    const hostDoc = await firestore.collection('users').doc(data.hostId).get();
    const hostName = hostDoc.exists ? hostDoc.data()!.displayName : 'Someone';

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: 'Group Video Call Invitation',
        body: `${hostName} invited you to "${data.title}"`,
      },
      data: {
        type: 'group_call_invitation',
        callId: data.callId,
      },
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending group call invitation:', error);
  }
}

async function sendParticipantRemovedNotification(userId: string, callId: string): Promise<void> {
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: 'Removed from Call',
        body: 'You have been removed from the group call',
      },
      data: {
        type: 'participant_removed',
        callId,
      },
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending participant removed notification:', error);
  }
}

async function sendBreakoutRoomInvitation(
  userId: string,
  data: { callId: string; roomId: string; title: string }
): Promise<void> {
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: 'Breakout Room Invitation',
        body: `You've been invited to "${data.title}"`,
      },
      data: {
        type: 'breakout_room_invitation',
        callId: data.callId,
        roomId: data.roomId,
      },
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending breakout room invitation:', error);
  }
}

async function sendBreakoutRoomClosed(
  userId: string,
  data: { callId: string; roomId: string }
): Promise<void> {
  try {
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken;
    if (!fcmToken) return;

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title: 'Breakout Room Closed',
        body: 'The breakout room has been closed. Returning to main call.',
      },
      data: {
        type: 'breakout_room_closed',
        callId: data.callId,
        roomId: data.roomId,
      },
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending breakout room closed notification:', error);
  }
}
