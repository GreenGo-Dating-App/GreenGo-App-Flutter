import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_report.dart';
import '../../../chat/data/models/message_model.dart';
import '../../../chat/domain/entities/message.dart';

/// Reports Admin Remote Data Source
///
/// Handles Firestore operations for admin report management
abstract class ReportsAdminRemoteDataSource {
  Future<List<MessageReport>> getPendingReports();
  Future<List<MessageReport>> getAllReports({int limit = 50});
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    required String adminId,
    String? actionTaken,
  });
  Future<List<Message>> getMessagesAroundReport({
    required String conversationId,
    required String messageId,
    int contextCount = 50,
  });
  Future<void> lockAccount({
    required String userId,
    required String adminId,
    required String reason,
    DateTime? lockUntil,
  });
  Future<void> unlockAccount({
    required String userId,
    required String adminId,
  });
  Future<List<Map<String, dynamic>>> getLockedAccounts();
}

class ReportsAdminRemoteDataSourceImpl implements ReportsAdminRemoteDataSource {
  final FirebaseFirestore firestore;

  ReportsAdminRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<MessageReport>> getPendingReports() async {
    try {
      final snapshot = await firestore
          .collection('message_reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('reportedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => _reportFromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get pending reports: $e');
    }
  }

  @override
  Future<List<MessageReport>> getAllReports({int limit = 50}) async {
    try {
      final snapshot = await firestore
          .collection('message_reports')
          .orderBy('reportedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _reportFromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get all reports: $e');
    }
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    required String adminId,
    String? actionTaken,
  }) async {
    try {
      await firestore.collection('message_reports').doc(reportId).update({
        'status': status.value,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        if (actionTaken != null) 'actionTaken': actionTaken,
      });
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  @override
  Future<List<Message>> getMessagesAroundReport({
    required String conversationId,
    required String messageId,
    int contextCount = 50,
  }) async {
    try {
      // Get the target message to find its timestamp
      final targetMessageDoc = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!targetMessageDoc.exists) {
        throw Exception('Message not found');
      }

      final targetTimestamp = targetMessageDoc.data()!['sentAt'] as Timestamp;

      // Get messages before (older)
      final beforeQuery = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('sentAt', isLessThan: targetTimestamp)
          .orderBy('sentAt', descending: true)
          .limit(contextCount)
          .get();

      // Get messages after (newer)
      final afterQuery = await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('sentAt', isGreaterThan: targetTimestamp)
          .orderBy('sentAt')
          .limit(contextCount)
          .get();

      // Combine results: before (reversed) + target + after
      final messages = <Message>[];

      // Add before messages (reverse to chronological order)
      final beforeMessages = beforeQuery.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList()
          .reversed;
      messages.addAll(beforeMessages);

      // Add target message
      messages.add(MessageModel.fromFirestore(targetMessageDoc));

      // Add after messages
      final afterMessages = afterQuery.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
      messages.addAll(afterMessages);

      return messages;
    } catch (e) {
      throw Exception('Failed to get messages around report: $e');
    }
  }

  @override
  Future<void> lockAccount({
    required String userId,
    required String adminId,
    required String reason,
    DateTime? lockUntil,
  }) async {
    try {
      await firestore.collection('profiles').doc(userId).update({
        'isLocked': true,
        'lockedAt': Timestamp.fromDate(DateTime.now()),
        'lockedBy': adminId,
        'lockReason': reason,
        'lockUntil': lockUntil != null ? Timestamp.fromDate(lockUntil) : null,
      });

      // Also record in account_actions for audit trail
      await firestore.collection('account_actions').add({
        'userId': userId,
        'action': 'lock',
        'adminId': adminId,
        'reason': reason,
        'lockUntil': lockUntil != null ? Timestamp.fromDate(lockUntil) : null,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to lock account: $e');
    }
  }

  @override
  Future<void> unlockAccount({
    required String userId,
    required String adminId,
  }) async {
    try {
      await firestore.collection('profiles').doc(userId).update({
        'isLocked': false,
        'lockedAt': null,
        'lockedBy': null,
        'lockReason': null,
        'lockUntil': null,
      });

      // Record unlock action
      await firestore.collection('account_actions').add({
        'userId': userId,
        'action': 'unlock',
        'adminId': adminId,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to unlock account: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLockedAccounts() async {
    try {
      final snapshot = await firestore
          .collection('profiles')
          .where('isLocked', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'lockedAt': (data['lockedAt'] as Timestamp?)?.toDate(),
          'lockReason': data['lockReason'] ?? '',
          'lockUntil': (data['lockUntil'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get locked accounts: $e');
    }
  }

  MessageReport _reportFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageReport(
      reportId: doc.id,
      messageId: data['messageId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      messageContent: data['messageContent'] ?? '',
      messageSentAt: (data['messageSentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reason: data['reason'] ?? '',
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ReportStatusExtension.fromString(data['status'] ?? 'pending'),
      reviewedBy: data['reviewedBy'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      actionTaken: data['actionTaken'],
    );
  }
}
