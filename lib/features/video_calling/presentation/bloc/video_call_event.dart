import '../../domain/entities/video_call.dart';

/// Video Call Events
abstract class VideoCallEvent {
  const VideoCallEvent();
}

/// Start listening for incoming calls
class VideoCallStartListening extends VideoCallEvent {
  final String userId;

  const VideoCallStartListening(this.userId);
}

/// Stop listening for incoming calls
class VideoCallStopListening extends VideoCallEvent {
  const VideoCallStopListening();
}

/// Incoming call received
class VideoCallIncoming extends VideoCallEvent {
  final VideoCall call;

  const VideoCallIncoming(this.call);
}

/// Initiate outgoing call
class VideoCallInitiate extends VideoCallEvent {
  final String callerId;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;

  const VideoCallInitiate({
    required this.callerId,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
  });
}

/// Answer incoming call
class VideoCallAnswer extends VideoCallEvent {
  final String callId;
  final String userId;

  const VideoCallAnswer({
    required this.callId,
    required this.userId,
  });
}

/// Decline incoming call
class VideoCallDecline extends VideoCallEvent {
  final String callId;
  final String userId;

  const VideoCallDecline({
    required this.callId,
    required this.userId,
  });
}

/// End active call
class VideoCallEnd extends VideoCallEvent {
  final String callId;
  final String userId;

  const VideoCallEnd({
    required this.callId,
    required this.userId,
  });
}

/// Toggle audio mute
class VideoCallToggleAudio extends VideoCallEvent {
  const VideoCallToggleAudio();
}

/// Toggle video mute
class VideoCallToggleVideo extends VideoCallEvent {
  const VideoCallToggleVideo();
}

/// Switch camera (front/back)
class VideoCallSwitchCamera extends VideoCallEvent {
  const VideoCallSwitchCamera();
}

/// Toggle speaker
class VideoCallToggleSpeaker extends VideoCallEvent {
  const VideoCallToggleSpeaker();
}

/// Remote user joined
class VideoCallRemoteUserJoined extends VideoCallEvent {
  final int remoteUid;

  const VideoCallRemoteUserJoined(this.remoteUid);
}

/// Remote user left
class VideoCallRemoteUserLeft extends VideoCallEvent {
  final int remoteUid;

  const VideoCallRemoteUserLeft(this.remoteUid);
}

/// Call status updated
class VideoCallStatusUpdated extends VideoCallEvent {
  final VideoCall call;

  const VideoCallStatusUpdated(this.call);
}

/// Connection quality changed
class VideoCallQualityChanged extends VideoCallEvent {
  final ConnectionQuality quality;

  const VideoCallQualityChanged(this.quality);
}

/// Call error occurred
class VideoCallError extends VideoCallEvent {
  final String message;

  const VideoCallError(this.message);
}

/// Call connected (Agora joined channel)
class VideoCallConnected extends VideoCallEvent {
  const VideoCallConnected();
}

/// Load call history
class VideoCallLoadHistory extends VideoCallEvent {
  final String userId;

  const VideoCallLoadHistory(this.userId);
}

/// Submit call feedback
class VideoCallSubmitFeedback extends VideoCallEvent {
  final String callId;
  final String userId;
  final int rating;
  final List<String>? issues;
  final String? comments;

  const VideoCallSubmitFeedback({
    required this.callId,
    required this.userId,
    required this.rating,
    this.issues,
    this.comments,
  });
}
