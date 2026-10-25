import 'package:equatable/equatable.dart';

/// What the user chose for a Buddy (server `BuddySettings`).
///
/// The builder asks only category ([topic]), [language], [tone], [name] and
/// [avatar]. [role], [level] and [cefr] are optional since 2026-10-24: the
/// server defaults them (friend / intermediate / none). They are still read
/// from older Buddies, and only sent when set.
class BuddySettings extends Equatable {
  const BuddySettings({
    required this.name,
    required this.avatar,
    required this.topic,
    required this.tone,
    required this.language,
    this.role,
    this.level,
    this.cefr,
    this.chatLanguage,
    this.userLanguage,
    this.checkInsEnabled = true,
  });

  final String name;

  /// A `buddy_avatars` document id, or a legacy drawn avatar `buddy_01..24`.
  final String avatar;
  final String topic;
  final String tone;
  final String language;
  final String? role;
  final String? level;
  final String? cefr;

  /// The language this chat is translated into (owner 2026-10-24): chosen
  /// at creation, fixed forever (the server refuses updates). The server
  /// translates every message once into it. Null on older Buddies (display
  /// then falls back to the app language) and when the builder leaves it to
  /// the server (which defaults it to [language]).
  final String? chatLanguage;

  /// The language the user writes in (owner 2026-10-25): chosen at creation,
  /// fixed. The server skips translating a user message already in the chat
  /// language and uses it as the translation source. Null on older Buddies.
  final String? userLanguage;
  final bool checkInsEnabled;

  /// The callable payload (`createBuddy {settings}`). Optional fields are
  /// left out when unset (the server refuses a `null` role or level).
  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'avatar': avatar,
        'topic': topic,
        'tone': tone,
        'language': language,
        if (role != null) 'role': role,
        if (level != null) 'level': level,
        if (cefr != null) 'cefr': cefr,
        if (chatLanguage != null) 'chatLanguage': chatLanguage,
        if (userLanguage != null) 'userLanguage': userLanguage,
        'checkInsEnabled': checkInsEnabled,
      };

  BuddySettings copyWith({
    String? name,
    String? avatar,
    String? topic,
    String? tone,
    String? language,
    bool? checkInsEnabled,
  }) =>
      BuddySettings(
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        topic: topic ?? this.topic,
        tone: tone ?? this.tone,
        language: language ?? this.language,
        role: role,
        level: level,
        cefr: cefr,
        chatLanguage: chatLanguage,
        userLanguage: userLanguage,
        checkInsEnabled: checkInsEnabled ?? this.checkInsEnabled,
      );

  @override
  List<Object?> get props =>
      [name, avatar, topic, role, tone, language, level, cefr, chatLanguage, userLanguage, checkInsEnabled];
}

/// One long-term fact the Buddy remembers (server `MemoryFact`).
class BuddyMemoryFact extends Equatable {
  const BuddyMemoryFact({required this.id, required this.text, this.at});

  final String id;
  final String text;
  final DateTime? at;

  @override
  List<Object?> get props => [id, text, at];
}

/// A Buddy (`ai_buddies/{uid}/buddies/{id}`).
class Buddy extends Equatable {
  const Buddy({
    required this.id,
    required this.settings,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    this.messageCount = 0,
    this.unansweredCheckIns = 0,
    this.memory = const <BuddyMemoryFact>[],
  });

  final String id;
  final BuddySettings settings;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final int messageCount;

  /// Check-ins the Buddy sent that the user has not answered yet.
  final int unansweredCheckIns;
  final List<BuddyMemoryFact> memory;

  String get name => settings.name;

  /// For "most recent first" lists: last activity, else creation.
  DateTime get activityAt => lastMessageAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  List<Object?> get props => [
        id,
        settings,
        lastMessage,
        lastMessageAt,
        createdAt,
        messageCount,
        unansweredCheckIns,
        memory,
      ];
}
