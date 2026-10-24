import 'package:equatable/equatable.dart';

/// Who wrote a Buddy chat message.
enum BuddyMessageRole { user, buddy }

/// `chat` = normal reply, `checkin` = the Buddy wrote first (free),
/// `safety` = fixed caring reply with helplines.
enum BuddyMessageKind { chat, checkin, safety }

/// Local delivery state of a message the user typed (server messages are
/// always [sent]).
enum BuddyDelivery { sent, sending, failed }

/// A place the Buddy named in a reply (server `BuddyKeyword`): `city`,
/// `attraction` or `country` + its name as written.
class BuddyKeyword extends Equatable {
  const BuddyKeyword({required this.type, required this.name});

  final String type;
  final String name;

  static const Set<String> types = {'city', 'attraction', 'country'};

  /// Null for anything that is not a valid `{type, name}` map.
  static BuddyKeyword? fromMap(Object? m) {
    if (m is! Map) return null;
    final type = m['type'], name = m['name'];
    if (type is! String || !types.contains(type) || name is! String || name.trim().isEmpty) {
      return null;
    }
    return BuddyKeyword(type: type, name: name.trim());
  }

  static List<BuddyKeyword> listFrom(Object? raw) => raw is List
      ? [for (final k in raw) if (fromMap(k) case final v?) v]
      : const <BuddyKeyword>[];

  @override
  List<Object?> get props => [type, name];
}

/// The server's translation of a message into the Buddy's `chatLanguage`
/// (message field `translation: {text, lang}`), made once when the message
/// is created. Absent when the message is already in that language or the
/// translation failed.
class BuddyTranslation extends Equatable {
  const BuddyTranslation({required this.text, this.lang});

  final String text;

  /// The language of [text] (the chat language), when the server sent it.
  final String? lang;

  /// Null for anything that is not a `{text, lang?}` map with a text.
  static BuddyTranslation? fromMap(Object? m) {
    if (m is! Map) return null;
    final text = m['text'], lang = m['lang'];
    if (text is! String || text.trim().isEmpty) return null;
    return BuddyTranslation(
      text: text,
      lang: lang is String && lang.isNotEmpty ? lang : null,
    );
  }

  /// From a callable result entry (a string, or null = no translation).
  static BuddyTranslation? fromText(Object? text, String? lang) =>
      text is String && text.trim().isNotEmpty ? BuddyTranslation(text: text, lang: lang) : null;

  @override
  List<Object?> get props => [text, lang];
}

/// One message in `ai_buddies/{uid}/buddies/{id}/messages`.
class BuddyMessage extends Equatable {
  const BuddyMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.kind = BuddyMessageKind.chat,
    this.charged = 'none',
    this.delivery = BuddyDelivery.sent,
    this.requestId,
    this.keywords = const <BuddyKeyword>[],
    this.translation,
  });

  final String id;
  final BuddyMessageRole role;
  final String text;
  final BuddyMessageKind kind;

  /// `free`, `credit`, `coin` or `none` (a turn is charged on its first bubble).
  final String charged;
  final DateTime createdAt;
  final BuddyDelivery delivery;

  /// Local messages only: the idempotency id reused when retrying.
  final String? requestId;

  /// Places named in this bubble (server metadata; may be empty).
  final List<BuddyKeyword> keywords;

  /// The stored translation into the chat language (server side, once).
  /// Local messages carry the callable's until the stored doc arrives.
  final BuddyTranslation? translation;

  bool get isBuddy => role == BuddyMessageRole.buddy;
  bool get isLocal => delivery != BuddyDelivery.sent || id.startsWith('local_');

  static BuddyMessageRole roleFrom(Object? v) =>
      v == 'user' ? BuddyMessageRole.user : BuddyMessageRole.buddy;

  static BuddyMessageKind kindFrom(Object? v) {
    switch (v) {
      case 'checkin':
        return BuddyMessageKind.checkin;
      case 'safety':
        return BuddyMessageKind.safety;
      default:
        return BuddyMessageKind.chat;
    }
  }

  BuddyMessage copyWith({BuddyDelivery? delivery, BuddyTranslation? translation}) =>
      BuddyMessage(
        id: id,
        role: role,
        text: text,
        createdAt: createdAt,
        kind: kind,
        charged: charged,
        delivery: delivery ?? this.delivery,
        requestId: requestId,
        keywords: keywords,
        translation: translation ?? this.translation,
      );

  @override
  List<Object?> get props =>
      [id, role, text, kind, charged, createdAt, delivery, requestId, keywords, translation];
}

/// A page of messages, oldest first, plus whether older ones exist.
class BuddyMessagePage extends Equatable {
  const BuddyMessagePage({required this.messages, required this.hasMore});

  final List<BuddyMessage> messages;
  final bool hasMore;

  @override
  List<Object?> get props => [messages, hasMore];
}
