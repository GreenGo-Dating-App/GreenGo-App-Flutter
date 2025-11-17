/**
 * Video Call Entity
 * Points 121-145: WebRTC video calling system
 */

import 'package:equatable/equatable.dart';

/// Video call (Points 121-124)
class VideoCall extends Equatable {
  final String callId;
  final String callerId;
  final String receiverId;
  final VideoCallType type;
  final VideoCallStatus status;
  final DateTime initiatedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final Duration? duration;
  final VideoCallQuality? quality;
  final Map<String, dynamic> callMetrics;
  final bool wasRecorded; // Point 127
  final String? recordingUrl;

  const VideoCall({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.type,
    required this.status,
    required this.initiatedAt,
    this.answeredAt,
    this.endedAt,
    this.duration,
    this.quality,
    required this.callMetrics,
    this.wasRecorded = false,
    this.recordingUrl,
  });

  bool get isActive =>
      status == VideoCallStatus.ringing || status == VideoCallStatus.active;

  bool get wasAnswered => answeredAt != null;

  @override
  List<Object?> get props => [
        callId,
        callerId,
        receiverId,
        type,
        status,
        initiatedAt,
        answeredAt,
        endedAt,
        duration,
        quality,
        callMetrics,
        wasRecorded,
        recordingUrl,
      ];
}

/// Video call type
enum VideoCallType {
  oneOnOne,
  group; // Point 141

  String get displayName {
    switch (this) {
      case VideoCallType.oneOnOne:
        return 'One-on-One';
      case VideoCallType.group:
        return 'Group Call';
    }
  }
}

/// Video call status
enum VideoCallStatus {
  ringing,
  active,
  ended,
  missed,
  declined,
  failed;

  String get displayName {
    switch (this) {
      case VideoCallStatus.ringing:
        return 'Ringing';
      case VideoCallStatus.active:
        return 'Active';
      case VideoCallStatus.ended:
        return 'Ended';
      case VideoCallStatus.missed:
        return 'Missed';
      case VideoCallStatus.declined:
        return 'Declined';
      case VideoCallStatus.failed:
        return 'Failed';
    }
  }
}

/// WebRTC configuration (Point 121)
class WebRTCConfig extends Equatable {
  final List<IceServer> iceServers;
  final String? stunServer;
  final String? turnServer;
  final IceTransportPolicy iceTransportPolicy;

  const WebRTCConfig({
    required this.iceServers,
    this.stunServer,
    this.turnServer,
    this.iceTransportPolicy = IceTransportPolicy.all,
  });

  /// Default STUN/TURN configuration
  static const WebRTCConfig defaultConfig = WebRTCConfig(
    iceServers: [
      IceServer(
        urls: ['stun:stun.l.google.com:19302'],
      ),
      IceServer(
        urls: ['stun:stun1.l.google.com:19302'],
      ),
    ],
    stunServer: 'stun:stun.l.google.com:19302',
  );

  @override
  List<Object?> get props => [
        iceServers,
        stunServer,
        turnServer,
        iceTransportPolicy,
      ];
}

/// ICE server configuration
class IceServer extends Equatable {
  final List<String> urls;
  final String? username;
  final String? credential;

  const IceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  @override
  List<Object?> get props => [urls, username, credential];
}

/// ICE transport policy
enum IceTransportPolicy {
  all,
  relay;
}

/// Agora/Twilio SDK configuration (Point 122)
class VideoSDKConfig extends Equatable {
  final VideoSDKProvider provider;
  final String appId;
  final String channelId;
  final String? token;
  final int uid;
  final VideoSDKMode mode;

  const VideoSDKConfig({
    required this.provider,
    required this.appId,
    required this.channelId,
    this.token,
    required this.uid,
    this.mode = VideoSDKMode.communication,
  });

  @override
  List<Object?> get props => [
        provider,
        appId,
        channelId,
        token,
        uid,
        mode,
      ];
}

/// Video SDK provider
enum VideoSDKProvider {
  agora,
  twilio,
  webrtc; // Fallback

  String get displayName {
    switch (this) {
      case VideoSDKProvider.agora:
        return 'Agora.io';
      case VideoSDKProvider.twilio:
        return 'Twilio Video';
      case VideoSDKProvider.webrtc:
        return 'WebRTC';
    }
  }
}

/// SDK mode
enum VideoSDKMode {
  communication, // Low latency
  broadcast; // One-to-many
}

/// Call signaling (Point 123)
class CallSignal extends Equatable {
  final String callId;
  final CallSignalType type;
  final String fromUserId;
  final String toUserId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  const CallSignal({
    required this.callId,
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    required this.data,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        callId,
        type,
        fromUserId,
        toUserId,
        data,
        timestamp,
      ];
}

/// Signal types
enum CallSignalType {
  offer,
  answer,
  iceCandidate,
  ringing,
  accept,
  decline,
  endCall;
}

/// Video quality (Point 125)
class VideoCallQuality extends Equatable {
  final VideoResolution resolution;
  final int bitrate; // kbps
  final int frameRate; // fps
  final ConnectionQuality connectionQuality;
  final NetworkStats networkStats;

  const VideoCallQuality({
    required this.resolution,
    required this.bitrate,
    required this.frameRate,
    required this.connectionQuality,
    required this.networkStats,
  });

  /// Auto-adjust quality based on bandwidth (Point 125)
  static VideoCallQuality forBandwidth(double bandwidthMbps) {
    if (bandwidthMbps >= 5.0) {
      // High bandwidth: 1080p
      return const VideoCallQuality(
        resolution: VideoResolution.hd1080,
        bitrate: 2500,
        frameRate: 30,
        connectionQuality: ConnectionQuality.excellent,
        networkStats: NetworkStats(
          latency: 50,
          jitter: 10,
          packetLoss: 0,
        ),
      );
    } else if (bandwidthMbps >= 2.0) {
      // Medium bandwidth: 720p
      return const VideoCallQuality(
        resolution: VideoResolution.hd720,
        bitrate: 1200,
        frameRate: 30,
        connectionQuality: ConnectionQuality.good,
        networkStats: NetworkStats(
          latency: 100,
          jitter: 20,
          packetLoss: 1,
        ),
      );
    } else {
      // Low bandwidth: 360p
      return const VideoCallQuality(
        resolution: VideoResolution.sd360,
        bitrate: 500,
        frameRate: 24,
        connectionQuality: ConnectionQuality.poor,
        networkStats: NetworkStats(
          latency: 200,
          jitter: 40,
          packetLoss: 5,
        ),
      );
    }
  }

  @override
  List<Object?> get props => [
        resolution,
        bitrate,
        frameRate,
        connectionQuality,
        networkStats,
      ];
}

/// Video resolution (Point 125, 131)
enum VideoResolution {
  sd360, // 640x360
  sd480, // 854x480
  hd720, // 1280x720
  hd1080; // 1920x1080

  int get width {
    switch (this) {
      case VideoResolution.sd360:
        return 640;
      case VideoResolution.sd480:
        return 854;
      case VideoResolution.hd720:
        return 1280;
      case VideoResolution.hd1080:
        return 1920;
    }
  }

  int get height {
    switch (this) {
      case VideoResolution.sd360:
        return 360;
      case VideoResolution.sd480:
        return 480;
      case VideoResolution.hd720:
        return 720;
      case VideoResolution.hd1080:
        return 1080;
    }
  }

  String get displayName => '${width}x$height';
}

/// Connection quality (Point 126)
enum ConnectionQuality {
  excellent, // 5 bars
  good, // 4 bars
  fair, // 3 bars
  poor, // 2 bars
  veryPoor; // 1 bar

  String get displayName {
    switch (this) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.veryPoor:
        return 'Very Poor';
    }
  }

  int get bars {
    switch (this) {
      case ConnectionQuality.excellent:
        return 5;
      case ConnectionQuality.good:
        return 4;
      case ConnectionQuality.fair:
        return 3;
      case ConnectionQuality.poor:
        return 2;
      case ConnectionQuality.veryPoor:
        return 1;
    }
  }
}

/// Network statistics (Point 126)
class NetworkStats extends Equatable {
  final int latency; // ms
  final int jitter; // ms
  final double packetLoss; // percentage

  const NetworkStats({
    required this.latency,
    required this.jitter,
    required this.packetLoss,
  });

  @override
  List<Object?> get props => [latency, jitter, packetLoss];
}

/// Call recording (Point 127)
class CallRecording extends Equatable {
  final String recordingId;
  final String callId;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration? duration;
  final String? storageUrl;
  final int fileSizeMB;
  final bool consentGiven; // Required
  final List<String> participants;

  const CallRecording({
    required this.recordingId,
    required this.callId,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.duration,
    this.storageUrl,
    required this.fileSizeMB,
    required this.consentGiven,
    required this.participants,
  });

  @override
  List<Object?> get props => [
        recordingId,
        callId,
        userId,
        startedAt,
        endedAt,
        duration,
        storageUrl,
        fileSizeMB,
        consentGiven,
        participants,
      ];
}

/// Call history entry (Point 128)
class CallHistoryEntry extends Equatable {
  final String callId;
  final String userId;
  final String otherUserId;
  final String? otherUserName;
  final String? otherUserPhotoUrl;
  final VideoCallType type;
  final VideoCallStatus status;
  final DateTime timestamp;
  final Duration? duration;
  final VideoCallQuality? quality;
  final bool wasIncoming;

  const CallHistoryEntry({
    required this.callId,
    required this.userId,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserPhotoUrl,
    required this.type,
    required this.status,
    required this.timestamp,
    this.duration,
    this.quality,
    required this.wasIncoming,
  });

  @override
  List<Object?> get props => [
        callId,
        userId,
        otherUserId,
        otherUserName,
        otherUserPhotoUrl,
        type,
        status,
        timestamp,
        duration,
        quality,
        wasIncoming,
      ];
}

/// Call statistics (Point 130)
class CallStatistics extends Equatable {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalCalls;
  final int answeredCalls;
  final int missedCalls;
  final Duration totalDuration;
  final double averageQuality; // 0-5
  final int connectionIssues;
  final Map<ConnectionQuality, int> qualityBreakdown;

  const CallStatistics({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalCalls,
    required this.answeredCalls,
    required this.missedCalls,
    required this.totalDuration,
    required this.averageQuality,
    required this.connectionIssues,
    required this.qualityBreakdown,
  });

  @override
  List<Object?> get props => [
        userId,
        periodStart,
        periodEnd,
        totalCalls,
        answeredCalls,
        missedCalls,
        totalDuration,
        averageQuality,
        connectionIssues,
        qualityBreakdown,
      ];
}

/// Video call features (Points 131-140)
class VideoCallFeatures extends Equatable {
  final bool hdVideoEnabled; // Point 131
  final bool hardwareAcceleration; // Point 131
  final VirtualBackground? virtualBackground; // Point 132
  final ARFilter? arFilter; // Point 133
  final BeautyMode? beautyMode; // Point 133
  final bool pictureInPictureEnabled; // Point 134
  final bool screenSharingEnabled; // Point 135 (Premium)
  final bool noiseSuppressionEnabled; // Point 137
  final bool echoCancellationEnabled; // Point 137
  final bool lowLightEnhancement; // Point 138

  const VideoCallFeatures({
    this.hdVideoEnabled = true,
    this.hardwareAcceleration = true,
    this.virtualBackground,
    this.arFilter,
    this.beautyMode,
    this.pictureInPictureEnabled = false,
    this.screenSharingEnabled = false,
    this.noiseSuppressionEnabled = true,
    this.echoCancellationEnabled = true,
    this.lowLightEnhancement = true,
  });

  @override
  List<Object?> get props => [
        hdVideoEnabled,
        hardwareAcceleration,
        virtualBackground,
        arFilter,
        beautyMode,
        pictureInPictureEnabled,
        screenSharingEnabled,
        noiseSuppressionEnabled,
        echoCancellationEnabled,
        lowLightEnhancement,
      ];
}

/// Virtual background (Point 132)
class VirtualBackground extends Equatable {
  final String backgroundId;
  final VirtualBackgroundType type;
  final String? imageUrl;
  final String? color;
  final bool blurEnabled;
  final int blurStrength; // 0-100

  const VirtualBackground({
    required this.backgroundId,
    required this.type,
    this.imageUrl,
    this.color,
    this.blurEnabled = false,
    this.blurStrength = 50,
  });

  @override
  List<Object?> get props => [
        backgroundId,
        type,
        imageUrl,
        color,
        blurEnabled,
        blurStrength,
      ];
}

enum VirtualBackgroundType {
  none,
  blur,
  image,
  color;
}

/// AR filter (Point 133)
class ARFilter extends Equatable {
  final String filterId;
  final String name;
  final String? iconUrl;
  final ARFilterType type;

  const ARFilter({
    required this.filterId,
    required this.name,
    this.iconUrl,
    required this.type,
  });

  @override
  List<Object?> get props => [filterId, name, iconUrl, type];
}

enum ARFilterType {
  faceSmoothing,
  eyeEnlargement,
  lipstick,
  sunglasses,
  crown,
  animalEars;
}

/// Beauty mode (Point 133)
class BeautyMode extends Equatable {
  final bool enabled;
  final int smoothness; // 0-100
  final int brightness; // 0-100
  final int eyeEnlargement; // 0-100

  const BeautyMode({
    this.enabled = false,
    this.smoothness = 50,
    this.brightness = 50,
    this.eyeEnlargement = 0,
  });

  @override
  List<Object?> get props => [
        enabled,
        smoothness,
        brightness,
        eyeEnlargement,
      ];
}

/// Call quality feedback (Point 140)
class CallFeedback extends Equatable {
  final String feedbackId;
  final String callId;
  final String userId;
  final int rating; // 1-5 stars
  final List<String> issues; // audio, video, connection, etc.
  final String? comments;
  final DateTime submittedAt;

  const CallFeedback({
    required this.feedbackId,
    required this.callId,
    required this.userId,
    required this.rating,
    required this.issues,
    this.comments,
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [
        feedbackId,
        callId,
        userId,
        rating,
        issues,
        comments,
        submittedAt,
      ];
}

/// Group video call (Points 141-145)
class GroupVideoCall extends Equatable {
  final String callId;
  final String hostUserId;
  final List<CallParticipant> participants;
  final int maxParticipants; // 6 for standard
  final GroupCallLayout layout; // Point 142
  final DateTime initiatedAt;
  final DateTime? endedAt;
  final GroupCallStatus status;
  final List<BreakoutRoom>? breakoutRooms; // Point 145

  const GroupVideoCall({
    required this.callId,
    required this.hostUserId,
    required this.participants,
    this.maxParticipants = 6,
    this.layout = GroupCallLayout.grid,
    required this.initiatedAt,
    this.endedAt,
    required this.status,
    this.breakoutRooms,
  });

  @override
  List<Object?> get props => [
        callId,
        hostUserId,
        participants,
        maxParticipants,
        layout,
        initiatedAt,
        endedAt,
        status,
        breakoutRooms,
      ];
}

/// Call participant (Point 143)
class CallParticipant extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final ParticipantRole role;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isSpeaking; // Point 142: Speaker detection
  final DateTime joinedAt;
  final DateTime? leftAt;

  const CallParticipant({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.role = ParticipantRole.participant,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.isSpeaking = false,
    required this.joinedAt,
    this.leftAt,
  });

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        role,
        isAudioMuted,
        isVideoMuted,
        isSpeaking,
        joinedAt,
        leftAt,
      ];
}

enum ParticipantRole {
  host,
  moderator,
  participant;
}

/// Group call layout (Point 142)
enum GroupCallLayout {
  grid, // Equal size tiles
  speaker, // Large speaker + small tiles
  spotlight; // Single large view
}

enum GroupCallStatus {
  waiting,
  active,
  ended;
}

/// Breakout room (Point 145)
class BreakoutRoom extends Equatable {
  final String roomId;
  final String name;
  final List<String> participantIds;
  final String? hostId;
  final DateTime createdAt;

  const BreakoutRoom({
    required this.roomId,
    required this.name,
    required this.participantIds,
    this.hostId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        roomId,
        name,
        participantIds,
        hostId,
        createdAt,
      ];
}
