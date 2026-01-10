import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/video_call.dart';
import '../models/video_call_model.dart';

/// Video Calling Remote Data Source
///
/// Handles Firestore and Cloud Functions operations for video calling
abstract class VideoCallingRemoteDataSource {
  /// Initiate a video call
  Future<VideoCallModel> initiateCall({
    required String callerId,
    required String receiverId,
    VideoCallType type = VideoCallType.oneOnOne,
  });

  /// Answer a call
  Future<VideoCallModel> answerCall({
    required String callId,
    required String userId,
  });

  /// Decline a call
  Future<void> declineCall({
    required String callId,
    required String userId,
  });

  /// End a call
  Future<void> endCall({
    required String callId,
    required String userId,
  });

  /// Get SDK config (Agora token)
  Future<VideoSDKConfigModel> getSDKConfig({
    required String callId,
    required String userId,
  });

  /// Listen for incoming calls
  Stream<VideoCallModel?> listenForIncomingCalls(String userId);

  /// Listen to call updates
  Stream<VideoCallModel> listenToCallUpdates(String callId);

  /// Send signal
  Future<void> sendSignal({
    required String callId,
    required CallSignalType type,
    required String fromUserId,
    required String toUserId,
    required Map<String, dynamic> data,
  });

  /// Listen to signals
  Stream<CallSignalModel> listenToSignals({
    required String callId,
    required String userId,
  });

  /// Update call quality
  Future<void> updateCallQuality({
    required String callId,
    required VideoCallQuality quality,
  });

  /// Get call history
  Future<List<CallHistoryEntryModel>> getCallHistory({
    required String userId,
    int limit = 50,
    DateTime? before,
  });

  /// Get call by ID
  Future<VideoCallModel> getCall(String callId);

  /// Toggle audio mute
  Future<void> toggleMuteAudio({
    required String callId,
    required String userId,
    required bool isMuted,
  });

  /// Toggle video mute
  Future<void> toggleMuteVideo({
    required String callId,
    required String userId,
    required bool isMuted,
  });

  /// Start recording
  Future<Map<String, dynamic>> startRecording({
    required String callId,
    required String userId,
    required bool consentGiven,
  });

  /// Stop recording
  Future<Map<String, dynamic>> stopRecording({
    required String callId,
    required String recordingId,
  });

  /// Submit feedback
  Future<void> submitFeedback({
    required String callId,
    required String userId,
    required int rating,
    List<String>? issues,
    String? comments,
  });

  /// Get call statistics
  Future<Map<String, dynamic>> getCallStatistics({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  });

  /// Get active call
  Future<VideoCallModel?> getActiveCall(String userId);
}

/// Implementation of VideoCallingRemoteDataSource
class VideoCallingRemoteDataSourceImpl implements VideoCallingRemoteDataSource {
  final FirebaseFirestore firestore;

  VideoCallingRemoteDataSourceImpl({required this.firestore});

  // Collection references
  CollectionReference get _callsCollection =>
      firestore.collection('video_calls');
  CollectionReference get _signalsCollection =>
      firestore.collection('call_signals');
  CollectionReference get _historyCollection =>
      firestore.collection('call_history');

  @override
  Future<VideoCallModel> initiateCall({
    required String callerId,
    required String receiverId,
    VideoCallType type = VideoCallType.oneOnOne,
  }) async {
    try {
      final callRef = _callsCollection.doc();
      final now = DateTime.now();

      final callData = {
        'callerId': callerId,
        'receiverId': receiverId,
        'type': type.name,
        'status': VideoCallStatus.ringing.name,
        'initiatedAt': Timestamp.fromDate(now),
        'callMetrics': {},
        'wasRecorded': false,
        'participants': [callerId, receiverId],
      };

      await callRef.set(callData);

      // Create call history entry for caller (outgoing)
      await _createCallHistoryEntry(
        callId: callRef.id,
        userId: callerId,
        otherUserId: receiverId,
        type: type,
        status: VideoCallStatus.ringing,
        wasIncoming: false,
      );

      // Create call history entry for receiver (incoming)
      await _createCallHistoryEntry(
        callId: callRef.id,
        userId: receiverId,
        otherUserId: callerId,
        type: type,
        status: VideoCallStatus.ringing,
        wasIncoming: true,
      );

      final doc = await callRef.get();
      return VideoCallModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to initiate call: $e');
    }
  }

  Future<void> _createCallHistoryEntry({
    required String callId,
    required String userId,
    required String otherUserId,
    required VideoCallType type,
    required VideoCallStatus status,
    required bool wasIncoming,
  }) async {
    // Get other user's info
    final otherUserDoc =
        await firestore.collection('users').doc(otherUserId).get();
    final otherUserData = otherUserDoc.data();

    await _historyCollection.doc('${callId}_$userId').set({
      'callId': callId,
      'userId': userId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserData?['displayName'] ?? 'Unknown',
      'otherUserPhotoUrl': otherUserData?['photoUrl'],
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'wasIncoming': wasIncoming,
    });
  }

  @override
  Future<VideoCallModel> answerCall({
    required String callId,
    required String userId,
  }) async {
    try {
      final callRef = _callsCollection.doc(callId);
      final now = DateTime.now();

      await callRef.update({
        'status': VideoCallStatus.active.name,
        'answeredAt': Timestamp.fromDate(now),
      });

      // Update call history entries
      await _updateCallHistoryStatus(callId, VideoCallStatus.active);

      final doc = await callRef.get();
      return VideoCallModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to answer call: $e');
    }
  }

  @override
  Future<void> declineCall({
    required String callId,
    required String userId,
  }) async {
    try {
      final callRef = _callsCollection.doc(callId);

      await callRef.update({
        'status': VideoCallStatus.declined.name,
        'endedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update call history
      await _updateCallHistoryStatus(callId, VideoCallStatus.declined);
    } catch (e) {
      throw Exception('Failed to decline call: $e');
    }
  }

  @override
  Future<void> endCall({
    required String callId,
    required String userId,
  }) async {
    try {
      final callRef = _callsCollection.doc(callId);
      final callDoc = await callRef.get();
      final callData = callDoc.data() as Map<String, dynamic>?;

      final now = DateTime.now();
      Duration? duration;

      if (callData != null && callData['answeredAt'] != null) {
        final answeredAt = (callData['answeredAt'] as Timestamp).toDate();
        duration = now.difference(answeredAt);
      }

      await callRef.update({
        'status': VideoCallStatus.ended.name,
        'endedAt': Timestamp.fromDate(now),
        'durationSeconds': duration?.inSeconds,
      });

      // Update call history with duration
      await _updateCallHistoryWithDuration(callId, duration);

      // Clean up signals
      await _cleanupSignals(callId);
    } catch (e) {
      throw Exception('Failed to end call: $e');
    }
  }

  Future<void> _updateCallHistoryStatus(
      String callId, VideoCallStatus status) async {
    final historyQuery =
        await _historyCollection.where('callId', isEqualTo: callId).get();

    for (final doc in historyQuery.docs) {
      await doc.reference.update({'status': status.name});
    }
  }

  Future<void> _updateCallHistoryWithDuration(
      String callId, Duration? duration) async {
    final historyQuery =
        await _historyCollection.where('callId', isEqualTo: callId).get();

    for (final doc in historyQuery.docs) {
      await doc.reference.update({
        'status': VideoCallStatus.ended.name,
        'durationSeconds': duration?.inSeconds,
      });
    }
  }

  Future<void> _cleanupSignals(String callId) async {
    final signalsQuery =
        await _signalsCollection.where('callId', isEqualTo: callId).get();

    for (final doc in signalsQuery.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<VideoSDKConfigModel> getSDKConfig({
    required String callId,
    required String userId,
  }) async {
    try {
      // In production, this would call a Cloud Function to generate an Agora token
      // For now, return a config with placeholder values
      // The actual token generation happens in the backend cloud function

      final callDoc = await _callsCollection.doc(callId).get();
      if (!callDoc.exists) {
        throw Exception('Call not found');
      }

      // Get or generate Agora config from the call document
      final callData = callDoc.data() as Map<String, dynamic>;

      // Check if SDK config already exists
      if (callData['sdkConfig'] != null) {
        return VideoSDKConfigModel.fromMap(
            callData['sdkConfig'] as Map<String, dynamic>);
      }

      // Generate a unique UID for this user in this call
      final uid = userId.hashCode.abs() % 1000000;

      // In production, call Cloud Function to get token
      // For now, create config without token (will need to be set up with Agora credentials)
      final sdkConfig = VideoSDKConfigModel(
        provider: VideoSDKProvider.agora,
        appId: '', // Set from environment/config
        channelId: callId,
        token: null, // Generated by Cloud Function
        uid: uid,
        mode: VideoSDKMode.communication,
      );

      return sdkConfig;
    } catch (e) {
      throw Exception('Failed to get SDK config: $e');
    }
  }

  @override
  Stream<VideoCallModel?> listenForIncomingCalls(String userId) {
    return _callsCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: VideoCallStatus.ringing.name)
        .orderBy('initiatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return VideoCallModel.fromFirestore(snapshot.docs.first);
    });
  }

  @override
  Stream<VideoCallModel> listenToCallUpdates(String callId) {
    return _callsCollection.doc(callId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Call not found');
      }
      return VideoCallModel.fromFirestore(snapshot);
    });
  }

  @override
  Future<void> sendSignal({
    required String callId,
    required CallSignalType type,
    required String fromUserId,
    required String toUserId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final signalRef = _signalsCollection.doc();
      await signalRef.set({
        'callId': callId,
        'type': type.name,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'data': data,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to send signal: $e');
    }
  }

  @override
  Stream<CallSignalModel> listenToSignals({
    required String callId,
    required String userId,
  }) {
    return _signalsCollection
        .where('callId', isEqualTo: callId)
        .where('toUserId', isEqualTo: userId)
        .orderBy('timestamp')
        .snapshots()
        .expand((snapshot) => snapshot.docChanges
            .where((change) => change.type == DocumentChangeType.added)
            .map((change) => CallSignalModel.fromFirestore(change.doc)));
  }

  @override
  Future<void> updateCallQuality({
    required String callId,
    required VideoCallQuality quality,
  }) async {
    try {
      await _callsCollection.doc(callId).update({
        'quality': {
          'resolution': quality.resolution.name,
          'bitrate': quality.bitrate,
          'frameRate': quality.frameRate,
          'connectionQuality': quality.connectionQuality.name,
          'networkStats': {
            'latency': quality.networkStats.latency,
            'jitter': quality.networkStats.jitter,
            'packetLoss': quality.networkStats.packetLoss,
          },
        },
      });
    } catch (e) {
      throw Exception('Failed to update call quality: $e');
    }
  }

  @override
  Future<List<CallHistoryEntryModel>> getCallHistory({
    required String userId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      Query query = _historyCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (before != null) {
        query = query.where('timestamp',
            isLessThan: Timestamp.fromDate(before));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => CallHistoryEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get call history: $e');
    }
  }

  @override
  Future<VideoCallModel> getCall(String callId) async {
    try {
      final doc = await _callsCollection.doc(callId).get();
      if (!doc.exists) {
        throw Exception('Call not found');
      }
      return VideoCallModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get call: $e');
    }
  }

  @override
  Future<void> toggleMuteAudio({
    required String callId,
    required String userId,
    required bool isMuted,
  }) async {
    try {
      await _callsCollection.doc(callId).update({
        'participants.$userId.isAudioMuted': isMuted,
      });
    } catch (e) {
      throw Exception('Failed to toggle audio: $e');
    }
  }

  @override
  Future<void> toggleMuteVideo({
    required String callId,
    required String userId,
    required bool isMuted,
  }) async {
    try {
      await _callsCollection.doc(callId).update({
        'participants.$userId.isVideoMuted': isMuted,
      });
    } catch (e) {
      throw Exception('Failed to toggle video: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> startRecording({
    required String callId,
    required String userId,
    required bool consentGiven,
  }) async {
    try {
      if (!consentGiven) {
        throw Exception('Recording requires consent from all participants');
      }

      final recordingRef = firestore.collection('call_recordings').doc();
      final recordingData = {
        'recordingId': recordingRef.id,
        'callId': callId,
        'userId': userId,
        'startedAt': Timestamp.fromDate(DateTime.now()),
        'consentGiven': consentGiven,
        'status': 'recording',
      };

      await recordingRef.set(recordingData);
      await _callsCollection.doc(callId).update({
        'wasRecorded': true,
        'activeRecordingId': recordingRef.id,
      });

      return recordingData;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> stopRecording({
    required String callId,
    required String recordingId,
  }) async {
    try {
      final recordingRef =
          firestore.collection('call_recordings').doc(recordingId);
      final now = DateTime.now();

      final recordingDoc = await recordingRef.get();
      final recordingData = recordingDoc.data() as Map<String, dynamic>;
      final startedAt = (recordingData['startedAt'] as Timestamp).toDate();
      final duration = now.difference(startedAt);

      await recordingRef.update({
        'endedAt': Timestamp.fromDate(now),
        'duration': duration.inSeconds,
        'status': 'completed',
      });

      await _callsCollection.doc(callId).update({
        'activeRecordingId': FieldValue.delete(),
      });

      return {
        ...recordingData,
        'endedAt': now,
        'duration': duration.inSeconds,
        'status': 'completed',
      };
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  @override
  Future<void> submitFeedback({
    required String callId,
    required String userId,
    required int rating,
    List<String>? issues,
    String? comments,
  }) async {
    try {
      final feedbackRef = firestore.collection('call_feedback').doc();
      await feedbackRef.set({
        'feedbackId': feedbackRef.id,
        'callId': callId,
        'userId': userId,
        'rating': rating,
        'issues': issues ?? [],
        'comments': comments,
        'submittedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCallStatistics({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final historyQuery = await _historyCollection
          .where('userId', isEqualTo: userId)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
          .get();

      int totalCalls = historyQuery.docs.length;
      int answeredCalls = 0;
      int missedCalls = 0;
      int totalDurationSeconds = 0;

      for (final doc in historyQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String;

        if (status == VideoCallStatus.ended.name) {
          answeredCalls++;
          totalDurationSeconds += (data['durationSeconds'] as int?) ?? 0;
        } else if (status == VideoCallStatus.missed.name) {
          missedCalls++;
        }
      }

      return {
        'userId': userId,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'totalCalls': totalCalls,
        'answeredCalls': answeredCalls,
        'missedCalls': missedCalls,
        'totalDurationSeconds': totalDurationSeconds,
      };
    } catch (e) {
      throw Exception('Failed to get call statistics: $e');
    }
  }

  @override
  Future<VideoCallModel?> getActiveCall(String userId) async {
    try {
      // Check for calls where user is caller
      var query = await _callsCollection
          .where('callerId', isEqualTo: userId)
          .where('status', whereIn: [
            VideoCallStatus.ringing.name,
            VideoCallStatus.active.name
          ])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return VideoCallModel.fromFirestore(query.docs.first);
      }

      // Check for calls where user is receiver
      query = await _callsCollection
          .where('receiverId', isEqualTo: userId)
          .where('status', whereIn: [
            VideoCallStatus.ringing.name,
            VideoCallStatus.active.name
          ])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return VideoCallModel.fromFirestore(query.docs.first);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get active call: $e');
    }
  }
}
