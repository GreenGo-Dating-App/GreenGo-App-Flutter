import '../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../core/services/chat_datasets/keyword_matcher.dart';
import 'message_insights.dart';

/// A place (attraction, city or country) named in a chat, from the message
/// metadata (`metadata['entities']`, see [MessageInsights]) or, for messages
/// sent before metadata existed, from the offline keyword index. No AI.
class ChatPlace {
  const ChatPlace({
    required this.match,
    required this.label,
    required this.at,
    required this.fromPartner,
    required this.iso2,
    required this.messageId,
  });

  /// The keyword match (kind + refs); [KeywordActions.open] opens it.
  final KeywordMatch match;

  /// The words as written in the chat ("Roma", "Colosseo").
  final String label;

  /// When it was last mentioned.
  final DateTime at;

  /// Last mentioned by the other person.
  final bool fromPartner;

  /// Country of the place (ISO2), when known.
  final String? iso2;

  /// The message it was last mentioned in.
  final String messageId;

  KeywordKind get kind => match.kind;

  /// Identity of the place: same kind + same first target.
  String get key => '${match.kind.code}:${match.refs.first}';

  /// Attraction ids (an ambiguous name can point to several).
  List<int> get attractionIds => kind == KeywordKind.attraction
      ? [for (final r in match.refs) int.tryParse(r)].whereType<int>().toList()
      : const [];
}

/// One chat message, as far as places are concerned.
typedef ChatPlaceSource = ({
  String id,
  String text,
  Map<String, dynamic>? metadata,
  DateTime sentAt,
  bool fromPartner,
});

class ChatPlaces {
  ChatPlaces._();

  /// Places named in [messages] (any order), newest mention first, each once.
  /// [index] matches old messages without stored entities (null = skip them).
  static List<ChatPlace> collect(Iterable<ChatPlaceSource> messages, {KeywordIndex? index}) {
    final sorted = messages.toList()..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final kw = index ?? ChatDatasets.instance.keywords;
    final out = <String, ChatPlace>{};
    for (final m in sorted) {
      final matches = MessageInsights.storedEntities(m.metadata, m.text) ?? kw?.match(m.text) ?? const <KeywordMatch>[];
      for (final k in matches) {
        if (k.refs.isEmpty) continue;
        final place = ChatPlace(
          match: k,
          label: m.text.substring(k.start, k.end),
          at: m.sentAt,
          fromPartner: m.fromPartner,
          iso2: countryOf(k, kw),
          messageId: m.id,
        );
        out.putIfAbsent(place.key, () => place);
      }
    }
    return out.values.toList();
  }

  /// Places of the newest message by the other person, if it is one of the
  /// last [within] messages of the chat (so suggestions stay on topic).
  static List<ChatPlace> latestFromPartner(List<ChatPlace> places, Iterable<ChatPlaceSource> messages,
      {int within = 3}) {
    final recent = (messages.toList()..sort((a, b) => b.sentAt.compareTo(a.sentAt))).take(within);
    for (final m in recent) {
      if (!m.fromPartner) continue;
      final hits = places.where((p) => p.messageId == m.id).toList();
      if (hits.isNotEmpty) return hits;
    }
    return const [];
  }

  /// ISO2 of the country a keyword belongs to.
  static String? countryOf(KeywordMatch k, KeywordIndex? kw) {
    final ref = k.refs.first;
    switch (k.kind) {
      case KeywordKind.country:
        return ref;
      case KeywordKind.city:
        final i = ref.indexOf(':');
        return i > 0 ? ref.substring(0, i) : null;
      case KeywordKind.attraction:
        return kw?.attractions[ref]?.firstOrNull;
    }
  }
}
