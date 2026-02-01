import 'package:equatable/equatable.dart';

/// Video Call Status
enum VideoCallStatus {
  pending,
  ringing,
  connecting,
  connected,
  ended,
  declined,
  missed,
  failed,
}

/// Video Call Entity
/// In-app video dating feature
class VideoCall extends Equatable {
  final String id;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;
  final String matchId;
  final String channelId;
  final String? token;
  final VideoCallStatus status;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final bool isVideoEnabled;
  final bool isAudioEnabled;

  const VideoCall({
    required this.id,
    required this.callerId,
    required this.callerName,
    this.callerPhotoUrl,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
    required this.matchId,
    required this.channelId,
    this.token,
    required this.status,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds,
    this.isVideoEnabled = true,
    this.isAudioEnabled = true,
  });

  bool get isActive =>
      status == VideoCallStatus.ringing ||
      status == VideoCallStatus.connecting ||
      status == VideoCallStatus.connected;

  @override
  List<Object?> get props => [
        id,
        callerId,
        callerName,
        callerPhotoUrl,
        receiverId,
        receiverName,
        receiverPhotoUrl,
        matchId,
        channelId,
        token,
        status,
        createdAt,
        answeredAt,
        endedAt,
        durationSeconds,
        isVideoEnabled,
        isAudioEnabled,
      ];

  VideoCall copyWith({
    String? id,
    String? callerId,
    String? callerName,
    String? callerPhotoUrl,
    String? receiverId,
    String? receiverName,
    String? receiverPhotoUrl,
    String? matchId,
    String? channelId,
    String? token,
    VideoCallStatus? status,
    DateTime? createdAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
    bool? isVideoEnabled,
    bool? isAudioEnabled,
  }) {
    return VideoCall(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhotoUrl: callerPhotoUrl ?? this.callerPhotoUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      matchId: matchId ?? this.matchId,
      channelId: channelId ?? this.channelId,
      token: token ?? this.token,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isAudioEnabled: isAudioEnabled ?? this.isAudioEnabled,
    );
  }
}

/// Call History Entry
class CallHistoryEntry extends Equatable {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final bool wasOutgoing;
  final VideoCallStatus status;
  final DateTime timestamp;
  final int? durationSeconds;

  const CallHistoryEntry({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.wasOutgoing,
    required this.status,
    required this.timestamp,
    this.durationSeconds,
  });

  @override
  List<Object?> get props => [
        id,
        otherUserId,
        otherUserName,
        otherUserPhotoUrl,
        wasOutgoing,
        status,
        timestamp,
        durationSeconds,
      ];
}
