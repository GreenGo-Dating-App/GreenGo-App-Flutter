/**
 * Video Calling Cloud Functions
 * Points 121-145: WebRTC, Agora.io, Group Calls
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();
const storage = admin.storage();

// Note: In production, install agora-access-token: npm install agora-access-token
// import { RtcTokenBuilder, RtcRole } from 'agora-access-token';

/**
 * Initiate Video Call
 * Points 121-123: WebRTC, Agora SDK, Firestore signaling
 */
export const initiateVideoCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const callerId = context.auth.uid;
  const { receiverId, callType, useWebRTC } = data;

  try {
    // Verify both users exist
    const [callerDoc, receiverDoc] = await Promise.all([
      firestore.collection('users').doc(callerId).get(),
      firestore.collection('users').doc(receiverId).get(),
    ]);

    if (!callerDoc.exists || !receiverDoc.exists) {
      throw new Error('User not found');
    }

    const callerData = callerDoc.data()!;
    const receiverData = receiverDoc.data()!;

    // Check if receiver is available
    if (receiverData.callStatus === 'busy') {
      throw new Error('User is currently in another call');
    }

    // Create video call document
    const callRef = firestore.collection('video_calls').doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    const callData = {
      callId: callRef.id,
      callerId,
      receiverId,
      callerName: callerData.displayName,
      callerPhotoUrl: callerData.photoUrls?.[0] || null,
      receiverName: receiverData.displayName,
      receiverPhotoUrl: receiverData.photoUrls?.[0] || null,
      callType, // 'audio' or 'video'
      status: 'ringing',
      initiatedAt: now,
      answeredAt: null,
      endedAt: null,
      duration: 0,
      sdkProvider: useWebRTC ? 'webrtc' : 'agora',
      agoraChannelName: useWebRTC ? null : `greengo_${callRef.id}`,
      quality: {
        resolution: 'hd720',
        bitrate: 1200,
        frameRate: 30,
      },
      features: {
        virtualBackgroundEnabled: false,
        beautyModeEnabled: false,
        arFiltersEnabled: false,
        noiseSuppression: true,
        echoCancellation: true,
      },
      networkStats: {
        packetLoss: 0,
        jitter: 0,
        latency: 0,
        bandwidth: 0,
      },
      recordingEnabled: false,
      recordingConsent: {
        callerConsent: false,
        receiverConsent: false,
      },
    };

    await callRef.set(callData);

    // Generate Agora token if using Agora SDK (Point 122)
    let agoraToken = null;
    if (!useWebRTC) {
      agoraToken = await generateAgoraToken(callRef.id, callerId);
    }

    // Create call signal for WebRTC (Point 123)
    if (useWebRTC) {
      const signalRef = firestore.collection('call_signals').doc(callRef.id);
      await signalRef.set({
        callId: callRef.id,
        callerId,
        receiverId,
        offer: null,
        answer: null,
        callerIceCandidates: [],
        receiverIceCandidates: [],
        createdAt: now,
      });
    }

    // Send push notification to receiver
    await sendCallNotification(receiverId, {
      callId: callRef.id,
      callerName: callerData.displayName,
      callerPhotoUrl: callerData.photoUrls?.[0],
      callType,
    });

    // Update user call status
    await Promise.all([
      firestore.collection('users').doc(callerId).update({ callStatus: 'calling' }),
      firestore.collection('users').doc(receiverId).update({ callStatus: 'ringing' }),
    ]);

    console.log(`Video call initiated: ${callRef.id}`);
    return {
      success: true,
      callId: callRef.id,
      agoraToken,
      agoraChannelName: callData.agoraChannelName,
    };
  } catch (error: any) {
    console.error('Error initiating video call:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Answer Video Call
 */
export const answerVideoCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId } = data;

  try {
    const callRef = firestore.collection('video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Call not found');
    }

    const callData = callDoc.data()!;

    if (callData.receiverId !== userId) {
      throw new Error('Unauthorized');
    }

    if (callData.status !== 'ringing') {
      throw new Error('Call is not in ringing state');
    }

    // Update call status
    await callRef.update({
      status: 'active',
      answeredAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user status
    await firestore.collection('users').doc(userId).update({
      callStatus: 'busy',
    });

    // Generate Agora token for receiver
    let agoraToken = null;
    if (callData.sdkProvider === 'agora') {
      agoraToken = await generateAgoraToken(callId, userId);
    }

    console.log(`Video call answered: ${callId}`);
    return {
      success: true,
      callId,
      agoraToken,
      agoraChannelName: callData.agoraChannelName,
    };
  } catch (error: any) {
    console.error('Error answering video call:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * End Video Call
 * Point 128: Call history tracking
 */
export const endVideoCall = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId, reason } = data;

  try {
    const callRef = firestore.collection('video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Call not found');
    }

    const callData = callDoc.data()!;

    if (callData.callerId !== userId && callData.receiverId !== userId) {
      throw new Error('Unauthorized');
    }

    // Calculate duration
    let duration = 0;
    if (callData.answeredAt) {
      const answeredAt = callData.answeredAt.toMillis();
      duration = Math.floor((Date.now() - answeredAt) / 1000);
    }

    // Update call status
    await callRef.update({
      status: reason === 'declined' ? 'declined' : 'ended',
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endReason: reason,
      duration,
    });

    // Stop recording if enabled (Point 127)
    if (callData.recordingEnabled) {
      await stopCallRecording(callId);
    }

    // Create call history entries (Point 128)
    const historyEntry = {
      callId,
      callType: callData.callType,
      duration,
      answeredAt: callData.answeredAt,
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      endReason: reason,
      quality: callData.quality,
      wasRecorded: callData.recordingEnabled,
    };

    await Promise.all([
      firestore.collection('users').doc(callData.callerId)
        .collection('call_history').doc(callId).set({
          ...historyEntry,
          otherUserId: callData.receiverId,
          otherUserName: callData.receiverName,
          otherUserPhotoUrl: callData.receiverPhotoUrl,
          direction: 'outgoing',
        }),
      firestore.collection('users').doc(callData.receiverId)
        .collection('call_history').doc(callId).set({
          ...historyEntry,
          otherUserId: callData.callerId,
          otherUserName: callData.callerName,
          otherUserPhotoUrl: callData.callerPhotoUrl,
          direction: 'incoming',
        }),
    ]);

    // Update user call status
    await Promise.all([
      firestore.collection('users').doc(callData.callerId).update({ callStatus: 'available' }),
      firestore.collection('users').doc(callData.receiverId).update({ callStatus: 'available' }),
    ]);

    // Update call statistics (Point 130)
    await updateCallStatistics(callData.callerId, callData);
    await updateCallStatistics(callData.receiverId, callData);

    console.log(`Video call ended: ${callId}`);
    return { success: true, duration };
  } catch (error: any) {
    console.error('Error ending video call:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Handle WebRTC Signaling
 * Point 123: Firestore signaling for offer/answer/ICE
 */
export const handleCallSignal = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId, signalType, signalData } = data;

  try {
    const signalRef = firestore.collection('call_signals').doc(callId);
    const signalDoc = await signalRef.get();

    if (!signalDoc.exists) {
      throw new Error('Call signal not found');
    }

    const signal = signalDoc.data()!;

    if (signal.callerId !== userId && signal.receiverId !== userId) {
      throw new Error('Unauthorized');
    }

    const isCaller = signal.callerId === userId;

    // Handle different signal types
    switch (signalType) {
      case 'offer':
        if (!isCaller) {
          throw new Error('Only caller can send offer');
        }
        await signalRef.update({ offer: signalData });
        break;

      case 'answer':
        if (isCaller) {
          throw new Error('Only receiver can send answer');
        }
        await signalRef.update({ answer: signalData });
        break;

      case 'ice_candidate':
        const field = isCaller ? 'callerIceCandidates' : 'receiverIceCandidates';
        await signalRef.update({
          [field]: admin.firestore.FieldValue.arrayUnion(signalData),
        });
        break;

      default:
        throw new Error('Invalid signal type');
    }

    console.log(`Call signal handled: ${callId} - ${signalType}`);
    return { success: true };
  } catch (error: any) {
    console.error('Error handling call signal:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Update Call Quality
 * Point 125: Auto-adjust quality based on bandwidth
 */
export const updateCallQuality = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { callId, networkStats } = data;

  try {
    const callRef = firestore.collection('video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Call not found');
    }

    // Calculate optimal quality based on bandwidth (Point 125)
    const bandwidthMbps = networkStats.bandwidth / 1000000;
    let quality;

    if (bandwidthMbps >= 5.0) {
      quality = { resolution: 'hd1080', bitrate: 2500, frameRate: 30 };
    } else if (bandwidthMbps >= 2.0) {
      quality = { resolution: 'hd720', bitrate: 1200, frameRate: 30 };
    } else if (bandwidthMbps >= 1.0) {
      quality = { resolution: 'sd480', bitrate: 800, frameRate: 24 };
    } else {
      quality = { resolution: 'sd360', bitrate: 500, frameRate: 24 };
    }

    // Update call with new quality and network stats
    await callRef.update({
      quality,
      networkStats,
      lastQualityUpdate: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, quality };
  } catch (error: any) {
    console.error('Error updating call quality:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Start Call Recording
 * Point 127: Recording with mutual consent
 */
export const startCallRecording = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { callId } = data;

  try {
    const callRef = firestore.collection('video_calls').doc(callId);
    const callDoc = await callRef.get();

    if (!callDoc.exists) {
      throw new Error('Call not found');
    }

    const callData = callDoc.data()!;

    if (callData.callerId !== userId && callData.receiverId !== userId) {
      throw new Error('Unauthorized');
    }

    // Set consent for the requesting user
    const isCaller = callData.callerId === userId;
    const consentField = isCaller ? 'recordingConsent.callerConsent' : 'recordingConsent.receiverConsent';

    await callRef.update({
      [consentField]: true,
    });

    // Check if both parties have consented
    const updatedDoc = await callRef.get();
    const updatedData = updatedDoc.data()!;

    const bothConsented = updatedData.recordingConsent.callerConsent &&
                          updatedData.recordingConsent.receiverConsent;

    if (bothConsented && !updatedData.recordingEnabled) {
      // Start recording
      await callRef.update({
        recordingEnabled: true,
        recordingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create recording document
      const recordingRef = firestore.collection('call_recordings').doc(callId);
      await recordingRef.set({
        recordingId: callId,
        callId,
        callerId: callData.callerId,
        receiverId: callData.receiverId,
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        endedAt: null,
        duration: 0,
        fileUrl: null,
        fileSize: 0,
        format: 'mp4',
        status: 'recording',
      });

      console.log(`Recording started for call: ${callId}`);
      return { success: true, recording: true };
    } else {
      console.log(`Waiting for other party consent: ${callId}`);
      return { success: true, recording: false, waitingForConsent: true };
    }
  } catch (error: any) {
    console.error('Error starting call recording:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Stop Call Recording
 * Point 127: Save recording to Cloud Storage
 */
async function stopCallRecording(callId: string): Promise<void> {
  try {
    const recordingRef = firestore.collection('call_recordings').doc(callId);
    const recordingDoc = await recordingRef.get();

    if (!recordingDoc.exists) {
      return;
    }

    const recordingData = recordingDoc.data()!;
    const duration = Math.floor((Date.now() - recordingData.startedAt.toMillis()) / 1000);

    // In production, finalize recording with Agora Cloud Recording API
    // const fileUrl = await finalizeAgoraRecording(callId);

    const fileUrl = `gs://greengo-recordings/${callId}.mp4`;

    await recordingRef.update({
      endedAt: admin.firestore.FieldValue.serverTimestamp(),
      duration,
      fileUrl,
      status: 'completed',
    });

    console.log(`Recording stopped for call: ${callId}`);
  } catch (error) {
    console.error('Error stopping call recording:', error);
  }
}

/**
 * Generate Agora Token
 * Point 122: Agora.io SDK integration
 */
async function generateAgoraToken(channelName: string, userId: string): Promise<string> {
  // In production, use actual Agora credentials:
  // const appId = functions.config().agora.app_id;
  // const appCertificate = functions.config().agora.app_certificate;
  // const expirationTimeInSeconds = 3600;
  // const currentTimestamp = Math.floor(Date.now() / 1000);
  // const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
  //
  // const token = RtcTokenBuilder.buildTokenWithUid(
  //   appId,
  //   appCertificate,
  //   channelName,
  //   parseInt(userId, 36),
  //   RtcRole.PUBLISHER,
  //   privilegeExpiredTs
  // );
  //
  // return token;

  // Placeholder for development
  return `agora_token_${channelName}_${userId}`;
}

/**
 * Send Call Notification
 */
async function sendCallNotification(
  userId: string,
  data: { callId: string; callerName: string; callerPhotoUrl?: string; callType: string }
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
        title: `Incoming ${data.callType} call`,
        body: `${data.callerName} is calling you`,
        imageUrl: data.callerPhotoUrl,
      },
      data: {
        type: 'incoming_video_call',
        callId: data.callId,
        callerId: data.callerName,
        callType: data.callType,
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'ringtone',
          channelId: 'video_calls',
          priority: 'max',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'ringtone.caf',
            category: 'INCOMING_CALL',
          },
        },
      },
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error('Error sending call notification:', error);
  }
}

/**
 * Update Call Statistics
 * Point 130: User call statistics
 */
async function updateCallStatistics(userId: string, callData: any): Promise<void> {
  try {
    const statsRef = firestore.collection('users').doc(userId).collection('statistics').doc('calls');
    const statsDoc = await statsRef.get();

    const isSuccessful = callData.status === 'ended' && callData.duration > 0;

    if (!statsDoc.exists) {
      await statsRef.set({
        totalCalls: 1,
        successfulCalls: isSuccessful ? 1 : 0,
        missedCalls: callData.status === 'declined' || callData.status === 'missed' ? 1 : 0,
        totalDuration: callData.duration || 0,
        averageDuration: callData.duration || 0,
        lastCallAt: admin.firestore.FieldValue.serverTimestamp(),
        callsByType: {
          audio: callData.callType === 'audio' ? 1 : 0,
          video: callData.callType === 'video' ? 1 : 0,
        },
      });
    } else {
      const stats = statsDoc.data()!;
      const newTotalCalls = stats.totalCalls + 1;
      const newTotalDuration = (stats.totalDuration || 0) + (callData.duration || 0);

      await statsRef.update({
        totalCalls: newTotalCalls,
        successfulCalls: admin.firestore.FieldValue.increment(isSuccessful ? 1 : 0),
        missedCalls: admin.firestore.FieldValue.increment(
          callData.status === 'declined' || callData.status === 'missed' ? 1 : 0
        ),
        totalDuration: newTotalDuration,
        averageDuration: Math.floor(newTotalDuration / newTotalCalls),
        lastCallAt: admin.firestore.FieldValue.serverTimestamp(),
        [`callsByType.${callData.callType}`]: admin.firestore.FieldValue.increment(1),
      });
    }
  } catch (error) {
    console.error('Error updating call statistics:', error);
  }
}
