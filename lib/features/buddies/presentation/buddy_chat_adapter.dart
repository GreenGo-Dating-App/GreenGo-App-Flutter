import '../../../core/services/chat_datasets/keyword_matcher.dart';
import '../../chat/domain/chat_places.dart';
import '../../chat/domain/entities/message.dart';
import '../domain/entities/buddy_message.dart';

/// Buddy chat messages rendered by the 1:1 chat's widgets ([MessageBubble],
/// [KeywordText], [ChatPlaces]): a [BuddyMessage] adapted to the chat
/// [Message] model.
///
/// Never sets `metadata['level']`: Buddy messages show no CEFR / difficulty
/// badge (owner 2026-10-24).
class BuddyChatAdapter {
  BuddyChatAdapter._();

  /// The sender id of a Buddy's messages (not a user id).
  static String buddySenderId(String buddyId) => 'buddy:$buddyId';

  /// [m] as a chat text message. [translated] is the automatic translation
  /// (null = none / same language); [index] the offline keyword index (null
  /// while it is loading: the bubble then matches keywords itself).
  static Message toMessage(
    BuddyMessage m, {
    required String uid,
    required String buddyId,
    required String buddyLanguage,
    String? translated,
    String? detectedLanguage,
    KeywordIndex? index,
  }) {
    final entities = keywordMatches(m.text, m.keywords, index);
    final buddy = buddySenderId(buddyId);
    final status = switch (m.delivery) {
      BuddyDelivery.sending => MessageStatus.sending,
      BuddyDelivery.failed => MessageStatus.failed,
      BuddyDelivery.sent => m.isLocal ? MessageStatus.sent : MessageStatus.read,
    };
    return Message(
      messageId: m.id,
      matchId: 'buddy_$buddyId',
      // Not a `conversations` doc: translation goes by text, not by message id.
      conversationId: '',
      senderId: m.isBuddy ? buddy : uid,
      receiverId: m.isBuddy ? uid : buddy,
      content: m.text,
      type: MessageType.text,
      sentAt: m.createdAt,
      status: status,
      // The Buddy has read a stored message of the user (double tick).
      readAt: !m.isBuddy && status == MessageStatus.read ? m.createdAt : null,
      metadata: <String, dynamic>{
        if (m.isBuddy) 'language': buddyLanguage,
        if (entities != null) 'entities': [for (final e in entities) e.toJson()],
      },
      translatedContent: translated,
      detectedLanguage: detectedLanguage ?? (m.isBuddy ? buddyLanguage : null),
    );
  }

  /// Keywords of [text] for highlights / the places bar: the offline matcher
  /// (like received messages) plus the places the server named in
  /// [keywords] that the matcher missed and the index can resolve (a
  /// keyword needs its target to be tappable). Null while [index] is null.
  static List<KeywordMatch>? keywordMatches(
      String text, List<BuddyKeyword> keywords, KeywordIndex? index) {
    if (index == null) return null;
    final out = [...index.match(text)];
    final lower = text.toLowerCase();
    // Offsets of the lower-cased text must be those of the text.
    if (keywords.isNotEmpty && lower.length == text.length) {
      for (final k in keywords) {
        final at = lower.indexOf(k.name.toLowerCase());
        if (at < 0) continue;
        final end = at + k.name.length;
        if (out.any((m) => m.start < end && at < m.end)) continue;
        final hits = index
            .match(k.name)
            .where((h) => h.start == 0 && h.end == k.name.length && h.refs.isNotEmpty)
            .toList();
        if (hits.isEmpty) continue;
        final want = kindOf(k.type);
        final h = hits.firstWhere((h) => h.kind == want, orElse: () => hits.first);
        out.add(KeywordMatch(start: at, end: end, kind: h.kind, refs: h.refs));
      }
      out.sort((a, b) => a.start.compareTo(b.start));
    }
    return out;
  }

  static KeywordKind kindOf(String type) => switch (type) {
        'attraction' => KeywordKind.attraction,
        'country' => KeywordKind.country,
        _ => KeywordKind.city,
      };

  /// The places bar / trip map input: the Buddy is the "partner".
  static ChatPlaceSource placeSource(Message m, String uid) => (
        id: m.messageId,
        text: m.content,
        metadata: m.metadata,
        sentAt: m.sentAt,
        fromPartner: m.senderId != uid,
      );
}
