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
  final String userId;

  const VideoCallListening(this.userId);
}

/// Incoming call ringing
class VideoCallRinging extends VideoCallState {
  final VideoCall call;
  final String callerName;
  final String? callerPhotoUrl;

  const VideoCallRinging({
    required this.call,
    required this.callerName,
    this.callerPhotoUrl,
  });
}

/// Outgoing call ringing
class VideoCallOutgoing extends VideoCallState {
  final VideoCall call;
  final String receiverName;
  final String? receiverPhotoUrl;

  const VideoCallOutgoing({
    required this.call,
    required this.receiverName,
    this.receiverPhotoUrl,
  });
}

/// Call connecting (setting up Agora)
class VideoCallConnecting extends VideoCallState {
  final VideoCall call;

  const VideoCallConnecting(this.call);
}

/// Active call in progress
class VideoCallActive extends VideoCallState {
  final VideoCall call;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final int? localUid;
  final int? remoteUid;
  final ConnectionQuality connectionQuality;
  final Duration callDuration;

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
  final VideoCall call;
  final Duration? duration;
  final String? endReason;

  const VideoCallEnded({
    required this.call,
    this.duration,
    this.endReason,
  });
}

/// Call declined
class VideoCallDeclined extends VideoCallState {
  final VideoCall call;

  const VideoCallDeclined(this.call);
}

/// Call missed
class VideoCallMissed extends VideoCallState {
  final VideoCall call;

  const VideoCallMissed(this.call);
}

/// Call error
class VideoCallFailure extends VideoCallState {
  final String message;
  final VideoCall? call;

  const VideoCallFailure(this.message, {this.call});
}

/// Call history loaded
class VideoCallHistoryLoaded extends VideoCallState {
  final List<CallHistoryEntry> history;

  const VideoCallHistoryLoaded(this.history);
}

/// Feedback submitted
class VideoCallFeedbackSubmitted extends VideoCallState {
  const VideoCallFeedbackSubmitted();
}
