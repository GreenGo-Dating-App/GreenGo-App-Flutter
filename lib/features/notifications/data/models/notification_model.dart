import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification.dart';

/// Notification Model
///
/// Data layer model for NotificationEntity with Firestore serialization
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.notificationId,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    super.data,
    required super.createdAt,
    super.isRead,
    super.actionUrl,
    super.imageUrl,
  });

  /// Create from NotificationEntity
  factory NotificationModel.fromEntity(NotificationEntity notification) {
    return NotificationModel(
      notificationId: notification.notificationId,
      userId: notification.userId,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      data: notification.data,
      createdAt: notification.createdAt,
      isRead: notification.isRead,
      actionUrl: notification.actionUrl,
      imageUrl: notification.imageUrl,
    );
  }

  /// Create from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      notificationId: doc.id,
      userId: data['userId'] as String,
      type: NotificationTypeExtension.fromString(data['type'] as String),
      title: data['title'] as String,
      message: data['message'] as String,
      data: data['data'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      actionUrl: data['actionUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  /// Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      userId: json['userId'] as String,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
    };
  }

  /// Convert to NotificationEntity
  NotificationEntity toEntity() {
    return NotificationEntity(
      notificationId: notificationId,
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data,
      createdAt: createdAt,
      isRead: isRead,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
    );
  }
}
