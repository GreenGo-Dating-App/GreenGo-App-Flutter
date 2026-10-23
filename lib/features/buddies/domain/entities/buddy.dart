import 'package:equatable/equatable.dart';

/// What the user chose for a Buddy (server `BuddySettings`).
class BuddySettings extends Equatable {
  const BuddySettings({
    required this.name,
    required this.avatar,
    required this.topic,
    required this.role,
    required this.tone,
    required this.language,
    required this.level,
    this.cefr,
    this.checkInsEnabled = true,
  });

  final String name;
  final String avatar;
  final String topic;
  final String role;
  final String tone;
  final String language;
  final String level;

  /// A1..C2 for language-practice topics, otherwise null.
  final String? cefr;
  final bool checkInsEnabled;

  /// The callable payload (`createBuddy {settings}`).
  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'avatar': avatar,
        'topic': topic,
        'role': role,
        'tone': tone,
        'language': language,
        'level': level,
        'cefr': cefr,
        'checkInsEnabled': checkInsEnabled,
      };

  BuddySettings copyWith({
    String? name,
    String? avatar,
    String? topic,
    String? role,
    String? tone,
    String? language,
    String? level,
    String? Function()? cefr,
    bool? checkInsEnabled,
  }) =>
      BuddySettings(
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        topic: topic ?? this.topic,
        role: role ?? this.role,
        tone: tone ?? this.tone,
        language: language ?? this.language,
        level: level ?? this.level,
        cefr: cefr != null ? cefr() : this.cefr,
        checkInsEnabled: checkInsEnabled ?? this.checkInsEnabled,
      );

  @override
  List<Object?> get props =>
      [name, avatar, topic, role, tone, language, level, cefr, checkInsEnabled];
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
  DateTime get activityAt =>
      lastMessageAt ?? createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

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
