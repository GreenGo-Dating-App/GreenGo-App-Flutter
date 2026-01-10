import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/video_call.dart';

/// VideoCall Model for Firestore serialization
class VideoCallModel extends VideoCall {
  const VideoCallModel({
    required super.callId,
    required super.callerId,
    required super.receiverId,
    required super.type,
    required super.status,
    required super.initiatedAt,
    super.answeredAt,
    super.endedAt,
    super.duration,
    super.quality,
    required super.callMetrics,
    super.wasRecorded,
    super.recordingUrl,
  });

  /// Create from Firestore document
  factory VideoCallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoCallModel(
      callId: doc.id,
      callerId: data['callerId'] as String,
      receiverId: data['receiverId'] as String,
      type: VideoCallType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => VideoCallType.oneOnOne,
      ),
      status: VideoCallStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => VideoCallStatus.ended,
      ),
      initiatedAt: (data['initiatedAt'] as Timestamp).toDate(),
      answeredAt: data['answeredAt'] != null
          ? (data['answeredAt'] as Timestamp).toDate()
          : null,
      endedAt: data['endedAt'] != null
          ? (data['endedAt'] as Timestamp).toDate()
          : null,
      duration: data['durationSeconds'] != null
          ? Duration(seconds: data['durationSeconds'] as int)
          : null,
      quality: data['quality'] != null
          ? VideoCallQualityModel.fromMap(
              data['quality'] as Map<String, dynamic>)
          : null,
      callMetrics: data['callMetrics'] as Map<String, dynamic>? ?? {},
      wasRecorded: data['wasRecorded'] as bool? ?? false,
      recordingUrl: data['recordingUrl'] as String?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'callerId': callerId,
      'receiverId': receiverId,
      'type': type.name,
      'status': status.name,
      'initiatedAt': Timestamp.fromDate(initiatedAt),
      'answeredAt':
          answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'durationSeconds': duration?.inSeconds,
      'callMetrics': callMetrics,
      'wasRecorded': wasRecorded,
      'recordingUrl': recordingUrl,
    };
  }

  /// Convert to entity
  VideoCall toEntity() => VideoCall(
        callId: callId,
        callerId: callerId,
        receiverId: receiverId,
        type: type,
        status: status,
        initiatedAt: initiatedAt,
        answeredAt: answeredAt,
        endedAt: endedAt,
        duration: duration,
        quality: quality,
        callMetrics: callMetrics,
        wasRecorded: wasRecorded,
        recordingUrl: recordingUrl,
      );

  /// Create from entity
  factory VideoCallModel.fromEntity(VideoCall entity) {
    return VideoCallModel(
      callId: entity.callId,
      callerId: entity.callerId,
      receiverId: entity.receiverId,
      type: entity.type,
      status: entity.status,
      initiatedAt: entity.initiatedAt,
      answeredAt: entity.answeredAt,
      endedAt: entity.endedAt,
      duration: entity.duration,
      quality: entity.quality,
      callMetrics: entity.callMetrics,
      wasRecorded: entity.wasRecorded,
      recordingUrl: entity.recordingUrl,
    );
  }
}

/// VideoCallQuality Model
class VideoCallQualityModel extends VideoCallQuality {
  const VideoCallQualityModel({
    required super.resolution,
    required super.bitrate,
    required super.frameRate,
    required super.connectionQuality,
    required super.networkStats,
  });

  factory VideoCallQualityModel.fromMap(Map<String, dynamic> map) {
    return VideoCallQualityModel(
      resolution: VideoResolution.values.firstWhere(
        (e) => e.name == map['resolution'],
        orElse: () => VideoResolution.hd720,
      ),
      bitrate: map['bitrate'] as int? ?? 1200,
      frameRate: map['frameRate'] as int? ?? 30,
      connectionQuality: ConnectionQuality.values.firstWhere(
        (e) => e.name == map['connectionQuality'],
        orElse: () => ConnectionQuality.good,
      ),
      networkStats: NetworkStatsModel.fromMap(
        map['networkStats'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'resolution': resolution.name,
      'bitrate': bitrate,
      'frameRate': frameRate,
      'connectionQuality': connectionQuality.name,
      'networkStats': (networkStats as NetworkStatsModel).toMap(),
    };
  }
}

/// NetworkStats Model
class NetworkStatsModel extends NetworkStats {
  const NetworkStatsModel({
    required super.latency,
    required super.jitter,
    required super.packetLoss,
  });

  factory NetworkStatsModel.fromMap(Map<String, dynamic> map) {
    return NetworkStatsModel(
      latency: map['latency'] as int? ?? 0,
      jitter: map['jitter'] as int? ?? 0,
      packetLoss: (map['packetLoss'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latency': latency,
      'jitter': jitter,
      'packetLoss': packetLoss,
    };
  }
}

/// CallSignal Model for WebRTC signaling
class CallSignalModel extends CallSignal {
  const CallSignalModel({
    required super.callId,
    required super.type,
    required super.fromUserId,
    required super.toUserId,
    required super.data,
    required super.timestamp,
  });

  factory CallSignalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallSignalModel(
      callId: data['callId'] as String,
      type: CallSignalType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CallSignalType.offer,
      ),
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      data: data['data'] as Map<String, dynamic>? ?? {},
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'callId': callId,
      'type': type.name,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  CallSignal toEntity() => CallSignal(
        callId: callId,
        type: type,
        fromUserId: fromUserId,
        toUserId: toUserId,
        data: data,
        timestamp: timestamp,
      );
}

/// CallHistoryEntry Model
class CallHistoryEntryModel extends CallHistoryEntry {
  const CallHistoryEntryModel({
    required super.callId,
    required super.userId,
    required super.otherUserId,
    super.otherUserName,
    super.otherUserPhotoUrl,
    required super.type,
    required super.status,
    required super.timestamp,
    super.duration,
    super.quality,
    required super.wasIncoming,
  });

  factory CallHistoryEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallHistoryEntryModel(
      callId: data['callId'] as String,
      userId: data['userId'] as String,
      otherUserId: data['otherUserId'] as String,
      otherUserName: data['otherUserName'] as String?,
      otherUserPhotoUrl: data['otherUserPhotoUrl'] as String?,
      type: VideoCallType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => VideoCallType.oneOnOne,
      ),
      status: VideoCallStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => VideoCallStatus.ended,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      duration: data['durationSeconds'] != null
          ? Duration(seconds: data['durationSeconds'] as int)
          : null,
      wasIncoming: data['wasIncoming'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'callId': callId,
      'userId': userId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhotoUrl': otherUserPhotoUrl,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'durationSeconds': duration?.inSeconds,
      'wasIncoming': wasIncoming,
    };
  }

  CallHistoryEntry toEntity() => CallHistoryEntry(
        callId: callId,
        userId: userId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhotoUrl: otherUserPhotoUrl,
        type: type,
        status: status,
        timestamp: timestamp,
        duration: duration,
        quality: quality,
        wasIncoming: wasIncoming,
      );
}

/// VideoSDKConfig Model for Agora token response
class VideoSDKConfigModel extends VideoSDKConfig {
  const VideoSDKConfigModel({
    required super.provider,
    required super.appId,
    required super.channelId,
    super.token,
    required super.uid,
    super.mode,
  });

  factory VideoSDKConfigModel.fromMap(Map<String, dynamic> map) {
    return VideoSDKConfigModel(
      provider: VideoSDKProvider.values.firstWhere(
        (e) => e.name == map['provider'],
        orElse: () => VideoSDKProvider.agora,
      ),
      appId: map['appId'] as String,
      channelId: map['channelId'] as String,
      token: map['token'] as String?,
      uid: map['uid'] as int? ?? 0,
      mode: VideoSDKMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => VideoSDKMode.communication,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider.name,
      'appId': appId,
      'channelId': channelId,
      'token': token,
      'uid': uid,
      'mode': mode.name,
    };
  }

  VideoSDKConfig toEntity() => VideoSDKConfig(
        provider: provider,
        appId: appId,
        channelId: channelId,
        token: token,
        uid: uid,
        mode: mode,
      );
}
