import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/conversation_expiry.dart';
import '../models/conversation_expiry_model.dart';

/// Remote data source for conversation expiry
abstract class ConversationExpiryRemoteDataSource {
  /// Get expiry for a conversation
  Future<ConversationExpiryModel?> getExpiry(String conversationId);

  /// Get all expiries for a user
  Future<List<ConversationExpiryModel>> getUserExpiries(String userId);

  /// Get expiring soon conversations
  Future<List<ConversationExpiryModel>> getExpiringSoon(
    String userId, {
    int withinHours = 24,
  });

  /// Extend a conversation
  Future<ExtensionResultModel> extendConversation({
    required String conversationId,
    required String userId,
  });

  /// Stream expiry updates
  Stream<ConversationExpiryModel> streamExpiry(String conversationId);

  /// Record activity
  Future<ConversationExpiryModel> recordActivity(String conversationId);

  /// Check if expired
  Future<bool> isExpired(String conversationId);
}

/// Implementation of conversation expiry remote data source
class ConversationExpiryRemoteDataSourceImpl
    implements ConversationExpiryRemoteDataSource {
  final FirebaseFunctions functions;
  final FirebaseFirestore firestore;

  ConversationExpiryRemoteDataSourceImpl({
    required this.functions,
    required this.firestore,
  });

  @override
  Future<ConversationExpiryModel?> getExpiry(String conversationId) async {
    final doc = await firestore
        .collection('conversationExpiry')
        .doc(conversationId)
        .get();

    if (!doc.exists) return null;
    return ConversationExpiryModel.fromFirestore(doc);
  }

  @override
  Future<List<ConversationExpiryModel>> getUserExpiries(String userId) async {
    final callable = functions.httpsCallable('getUserConversationExpiries');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
    });

    final expiries = result.data['expiries'] as List<dynamic>;
    return expiries
        .map((e) => ConversationExpiryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ConversationExpiryModel>> getExpiringSoon(
    String userId, {
    int withinHours = 24,
  }) async {
    final callable = functions.httpsCallable('getExpiringSoonConversations');
    final result = await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'withinHours': withinHours,
    });

    final expiries = result.data['expiries'] as List<dynamic>;
    return expiries
        .map((e) => ConversationExpiryModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ExtensionResultModel> extendConversation({
    required String conversationId,
    required String userId,
  }) async {
    final callable = functions.httpsCallable('extendConversation');
    final result = await callable.call<Map<String, dynamic>>({
      'conversationId': conversationId,
      'userId': userId,
    });

    return ExtensionResultModel.fromMap(result.data);
  }

  @override
  Stream<ConversationExpiryModel> streamExpiry(String conversationId) {
    return firestore
        .collection('conversationExpiry')
        .doc(conversationId)
        .snapshots()
        .where((doc) => doc.exists)
        .map((doc) => ConversationExpiryModel.fromFirestore(doc));
  }

  @override
  Future<ConversationExpiryModel> recordActivity(String conversationId) async {
    final callable = functions.httpsCallable('recordConversationActivity');
    final result = await callable.call<Map<String, dynamic>>({
      'conversationId': conversationId,
    });

    return ConversationExpiryModel.fromMap(
      result.data['expiry'] as Map<String, dynamic>,
    );
  }

  @override
  Future<bool> isExpired(String conversationId) async {
    final doc = await firestore
        .collection('conversationExpiry')
        .doc(conversationId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    return DateTime.now().isAfter(expiresAt);
  }
}
