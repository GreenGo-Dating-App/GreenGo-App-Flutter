import '../../domain/entities/video_call.dart';

/// Video Call Events
abstract class VideoCallEvent {
  const VideoCallEvent();
}

/// Start listening for incoming calls
class VideoCallStartListening extends VideoCallEvent {

  const VideoCallStartListening(this.userId);
  final String userId;
}

/// Stop listening for incoming calls
class VideoCallStopListening extends VideoCallEvent {
  const VideoCallStopListening();
}

/// Incoming call received
class VideoCallIncoming extends VideoCallEvent {

  const VideoCallIncoming(this.call);
  final VideoCall call;
}

/// Initiate outgoing call
class VideoCallInitiate extends VideoCallEvent {

  const VideoCallInitiate({
    required this.callerId,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
  });
  final String callerId;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
}

/// Answer incoming call
class VideoCallAnswer extends VideoCallEvent {

  const VideoCallAnswer({
    required this.callId,
    required this.userId,
  });
  final String callId;
  final String userId;
}

/// Decline incoming call
class VideoCallDecline extends VideoCallEvent {

  const VideoCallDecline({
    required this.callId,
    required this.userId,
  });
  final String callId;
  final String userId;
}

/// End active call
class VideoCallEnd extends VideoCallEvent {

  const VideoCallEnd({
    required this.callId,
    required this.userId,
  });
  final String callId;
  final String userId;
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

  const VideoCallRemoteUserJoined(this.remoteUid);
  final int remoteUid;
}

/// Remote user left
class VideoCallRemoteUserLeft extends VideoCallEvent {

  const VideoCallRemoteUserLeft(this.remoteUid);
  final int remoteUid;
}

/// Call status updated
class VideoCallStatusUpdated extends VideoCallEvent {

  const VideoCallStatusUpdated(this.call);
  final VideoCall call;
}

/// Connection quality changed
class VideoCallQualityChanged extends VideoCallEvent {

  const VideoCallQualityChanged(this.quality);
  final ConnectionQuality quality;
}

/// Call error occurred
class VideoCallError extends VideoCallEvent {

  const VideoCallError(this.message);
  final String message;
}

/// Call connected (Agora joined channel)
class VideoCallConnected extends VideoCallEvent {
  const VideoCallConnected();
}

/// Load call history
class VideoCallLoadHistory extends VideoCallEvent {

  const VideoCallLoadHistory(this.userId);
  final String userId;
}

/// Submit call feedback
class VideoCallDurationTick extends VideoCallEvent {
  const VideoCallDurationTick(this.duration);
  final Duration duration;
}

class VideoCallSubmitFeedback extends VideoCallEvent {

  const VideoCallSubmitFeedback({
    required this.callId,
    required this.userId,
    required this.rating,
    this.issues,
    this.comments,
  });
  final String callId;
  final String userId;
  final int rating;
  final List<String>? issues;
  final String? comments;
}
