import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/video_call.dart';

/// Video Calling Repository
///
/// Contract for video calling operations
abstract class VideoCallingRepository {
  /// Initiate a video call to another user
  Future<Either<Failure, VideoCall>> initiateCall({
    required String callerId,
    required String receiverId,
    VideoCallType type = VideoCallType.oneOnOne,
  });

  /// Answer an incoming call
  Future<Either<Failure, VideoCall>> answerCall({
    required String callId,
    required String userId,
  });

  /// Decline an incoming call
  Future<Either<Failure, void>> declineCall({
    required String callId,
    required String userId,
  });

  /// End an active call
  Future<Either<Failure, void>> endCall({
    required String callId,
    required String userId,
  });

  /// Get Agora SDK configuration (token, channel, etc.)
  Future<Either<Failure, VideoSDKConfig>> getSDKConfig({
    required String callId,
    required String userId,
  });

  /// Stream of incoming calls for a user
  Stream<Either<Failure, VideoCall?>> listenForIncomingCalls(String userId);

  /// Stream of call status updates
  Stream<Either<Failure, VideoCall>> listenToCallUpdates(String callId);

  /// Send WebRTC signal (offer, answer, ICE candidate)
  Future<Either<Failure, void>> sendSignal({
    required String callId,
    required CallSignalType type,
    required String fromUserId,
    required String toUserId,
    required Map<String, dynamic> data,
  });

  /// Stream of WebRTC signals for a call
  Stream<Either<Failure, CallSignal>> listenToSignals({
    required String callId,
    required String userId,
  });

  /// Update call quality metrics
  Future<Either<Failure, void>> updateCallQuality({
    required String callId,
    required VideoCallQuality quality,
  });

  /// Get call history for a user
  Future<Either<Failure, List<CallHistoryEntry>>> getCallHistory({
    required String userId,
    int limit = 50,
    DateTime? before,
  });

  /// Get a specific call by ID
  Future<Either<Failure, VideoCall>> getCall(String callId);

  /// Toggle mute audio
  Future<Either<Failure, void>> toggleMuteAudio({
    required String callId,
    required String userId,
    required bool isMuted,
  });

  /// Toggle mute video
  Future<Either<Failure, void>> toggleMuteVideo({
    required String callId,
    required String userId,
    required bool isMuted,
  });

  /// Switch camera (front/back)
  Future<Either<Failure, void>> switchCamera();

  /// Enable/disable speaker
  Future<Either<Failure, void>> toggleSpeaker(bool enabled);

  /// Start call recording (requires consent)
  Future<Either<Failure, CallRecording>> startRecording({
    required String callId,
    required String userId,
    required bool consentGiven,
  });

  /// Stop call recording
  Future<Either<Failure, CallRecording>> stopRecording({
    required String callId,
    required String recordingId,
  });

  /// Submit call quality feedback
  Future<Either<Failure, void>> submitFeedback({
    required String callId,
    required String userId,
    required int rating,
    List<String>? issues,
    String? comments,
  });

  /// Get call statistics for a user
  Future<Either<Failure, CallStatistics>> getCallStatistics({
    required String userId,
    required DateTime periodStart,
    required DateTime periodEnd,
  });

  /// Enable virtual background
  Future<Either<Failure, void>> setVirtualBackground({
    required VirtualBackground background,
  });

  /// Enable/disable beauty mode
  Future<Either<Failure, void>> setBeautyMode({
    required BeautyMode beautyMode,
  });

  /// Enable/disable noise suppression
  Future<Either<Failure, void>> toggleNoiseSuppression(bool enabled);

  /// Check if user is in an active call
  Future<Either<Failure, VideoCall?>> getActiveCall(String userId);
}
