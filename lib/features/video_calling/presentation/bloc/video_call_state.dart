import '../../domain/entities/video_call.dart';

/// Video Call States
abstract class VideoCallState {
  const VideoCallState();
}

/// Initial state - no active call
class VideoCallInitial extends VideoCallState {
  const VideoCallInitial();
}

/// Listening for incoming calls
class VideoCallListening extends VideoCallState {

  const VideoCallListening(this.userId);
  final String userId;
}

/// Incoming call ringing
class VideoCallRinging extends VideoCallState {

  const VideoCallRinging({
    required this.call,
    required this.callerName,
    this.callerPhotoUrl,
  });
  final VideoCall call;
  final String callerName;
  final String? callerPhotoUrl;
}

/// Outgoing call ringing
class VideoCallOutgoing extends VideoCallState {

  const VideoCallOutgoing({
    required this.call,
    required this.receiverName,
    this.receiverPhotoUrl,
  });
  final VideoCall call;
  final String receiverName;
  final String? receiverPhotoUrl;
}

/// Call connecting (setting up Agora)
class VideoCallConnecting extends VideoCallState {

  const VideoCallConnecting(this.call);
  final VideoCall call;
}

/// Active call in progress
class VideoCallActive extends VideoCallState {

  const VideoCallActive({
    required this.call,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.isSpeakerOn = false,
    this.isFrontCamera = true,
    this.localUid,
    this.remoteUid,
    this.connectionQuality = ConnectionQuality.good,
    this.callDuration = Duration.zero,
  });
  final VideoCall call;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final int? localUid;
  final int? remoteUid;
  final ConnectionQuality connectionQuality;
  final Duration callDuration;

  VideoCallActive copyWith({
    VideoCall? call,
    bool? isAudioMuted,
    bool? isVideoMuted,
    bool? isSpeakerOn,
    bool? isFrontCamera,
    int? localUid,
    int? remoteUid,
    ConnectionQuality? connectionQuality,
    Duration? callDuration,
  }) {
    return VideoCallActive(
      call: call ?? this.call,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      localUid: localUid ?? this.localUid,
      remoteUid: remoteUid ?? this.remoteUid,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      callDuration: callDuration ?? this.callDuration,
    );
  }
}

/// Call ended
class VideoCallEnded extends VideoCallState {

  const VideoCallEnded({
    required this.call,
    this.duration,
    this.endReason,
  });
  final VideoCall call;
  final Duration? duration;
  final String? endReason;
}

/// Call declined
class VideoCallDeclined extends VideoCallState {

  const VideoCallDeclined(this.call);
  final VideoCall call;
}

/// Call missed
class VideoCallMissed extends VideoCallState {

  const VideoCallMissed(this.call);
  final VideoCall call;
}

/// Call error
class VideoCallFailure extends VideoCallState {

  const VideoCallFailure(this.message, {this.call});
  final String message;
  final VideoCall? call;
}

/// Call history loaded
class VideoCallHistoryLoaded extends VideoCallState {

  const VideoCallHistoryLoaded(this.history);
  final List<CallHistoryEntry> history;
}

/// Feedback submitted
class VideoCallFeedbackSubmitted extends VideoCallState {
  const VideoCallFeedbackSubmitted();
}
