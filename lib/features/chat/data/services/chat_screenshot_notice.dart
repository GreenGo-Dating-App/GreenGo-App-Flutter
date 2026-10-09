import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/chat_system_message.dart';

/// Posts "X took a screenshot" into a 1:1 or group chat.
///
/// Client-written system line (see `chat_system_message.dart`): `type:
/// 'system'`, `metadata.systemKey = screenshotTaken`, `systemParams.name`,
/// with an English `content` fallback for old app versions and push. The
/// sender is the person who took the screenshot (the rules only let a member
/// post as themselves), so nobody can fake a notice about someone else.
///
/// Throttled per chat ([minInterval]) so a burst of screenshots is one line.
class ChatScreenshotNotice {
  ChatScreenshotNotice({
    FirebaseFirestore? firestore,
    this.minInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  })  : _firestore = firestore,
        _clock = clock ?? DateTime.now;

  final FirebaseFirestore? _firestore;
  final Duration minInterval;
  final DateTime Function() _clock;
  final Map<String, DateTime> _lastPosted = {};

  FirebaseFirestore get _fs => _firestore ?? FirebaseFirestore.instance;

  /// English fallback stored in `content` (not UI: readers render the key).
  static String fallbackContent(String name) =>
      '${name.trim().isNotEmpty ? name.trim() : 'Someone'} took a screenshot';

  bool _throttled(String chatKey) {
    final now = _clock();
    final last = _lastPosted[chatKey];
    if (last != null && now.difference(last) < minInterval) return true;
    _lastPosted[chatKey] = now;
    return false;
  }

  /// 1:1 chat: `conversations/{conversationId}/messages`. Returns whether a
  /// line was written.
  Future<bool> postToConversation({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String senderName,
  }) async {
    if (conversationId.isEmpty || senderId.isEmpty) return false;
    if (_throttled('c:$conversationId')) return false;
    try {
      final ref = _fs
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();
      await ref.set({
        'messageId': ref.id,
        'matchId': conversationId,
        'conversationId': conversationId,
        'senderId': senderId,
        'receiverId': receiverId,
        'content': fallbackContent(senderName),
        'type': 'system',
        'metadata': chatSystemMetadata(
            ChatSystemKey.screenshotTaken, {'name': senderName}),
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
      return true;
    } catch (e) {
      debugPrint('[ChatScreenshotNotice] conversation write failed: $e');
      return false;
    }
  }

  /// Group chat: `groups/{groupId}/messages` (the fan-out function updates
  /// inboxes, as for any group message).
  Future<bool> postToGroup({
    required String groupId,
    required String senderId,
    required String senderName,
  }) async {
    if (groupId.isEmpty || senderId.isEmpty) return false;
    if (_throttled('g:$groupId')) return false;
    try {
      final ref = _fs.collection('groups').doc(groupId).collection('messages').doc();
      await ref.set({
        'senderId': senderId,
        'receiverId': '',
        'matchId': groupId,
        'content': fallbackContent(senderName),
        'type': 'system',
        'status': 'sent',
        'sentAt': FieldValue.serverTimestamp(),
        'metadata': chatSystemMetadata(
            ChatSystemKey.screenshotTaken, {'name': senderName}),
      });
      return true;
    } catch (e) {
      debugPrint('[ChatScreenshotNotice] group write failed: $e');
      return false;
    }
  }
}
