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

  /// "pt_BR" / "pt-BR" / "pt" -> "pt".
  static String baseLanguage(String code) =>
      code.toLowerCase().replaceAll('_', '-').split('-').first;

  /// The stored translation of [m] to show, or null = show the text once
  /// (no translated layout, no "original" line). Null when there is none,
  /// when the chat language is the Buddy's language (it/it, pt/pt_BR), or
  /// when it only differs from the text in case, accents or punctuation.
  static String? shownTranslation(BuddyMessage m,
      {required String chatLanguage, required String buddyLanguage}) {
    final t = m.translation?.text;
    if (t == null || t.trim().isEmpty) return null;
    if (baseLanguage(chatLanguage) == baseLanguage(buddyLanguage)) return null;
    final lang = m.translation?.lang;
    if (lang != null && m.isBuddy && baseLanguage(lang) == baseLanguage(buddyLanguage)) return null;
    // A translation into another language (e.g. an old English one in the
    // device cache) is never shown in a chat translated into Italian.
    if (lang != null && baseLanguage(lang) != baseLanguage(chatLanguage)) return null;
    if (sameText(t, m.text)) return null;
    return t;
  }

  /// Equal ignoring case, accents, punctuation and spacing.
  static bool sameText(String a, String b) => _fold(a) == _fold(b);

  static const String _from = 'àáâãäåāăąçćčďèéêëēĕėęěìíîïĩīĭįıñńňòóôõöøōŏőùúûüũūŭůűųýÿžźżśšşřŕľĺłţťğß';
  static const String _to = 'aaaaaaaaacccdeeeeeeeeeiiiiiiiiinnnooooooooouuuuuuuuuuyyzzzsssrrlllttgs';
  static final RegExp _noise = RegExp(r'[\s\p{P}\p{S}]', unicode: true);

  static String _fold(String s) {
    final lower = s.toLowerCase();
    final out = StringBuffer();
    for (final r in lower.runes) {
      final ch = String.fromCharCode(r);
      final i = _from.indexOf(ch);
      out.write(i >= 0 ? _to[i] : ch);
    }
    return out.toString().replaceAll(_noise, '');
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
