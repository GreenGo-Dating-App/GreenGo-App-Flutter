import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greengo_chat/core/services/app_sound_service.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_exception.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_avatar_option.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/domain/repositories/buddies_repository.dart';
import 'package:greengo_chat/features/buddies/presentation/widgets/buddy_prompts.dart';

Buddy fakeBuddy(
  String id, {
  String name = 'Sunny',
  String topic = 'movies',
  String avatar = 'buddy_02',
  DateTime? createdAt,
  DateTime? lastMessageAt,
  String? lastMessage,
  List<BuddyMemoryFact> memory = const [],
  String language = 'en',
  String? chatLanguage,
}) =>
    Buddy(
      id: id,
      settings: BuddySettings(
        name: name,
        avatar: avatar,
        topic: topic,
        tone: 'warm',
        language: language,
        chatLanguage: chatLanguage,
      ),
      createdAt: createdAt ?? DateTime(2026, 10, 1),
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage,
      memory: memory,
    );

BuddyMessage fakeMessage(String id, BuddyMessageRole role, String text, DateTime at,
        {BuddyMessageKind kind = BuddyMessageKind.chat,
        String? translation,
        String? lang,
        List<BuddySegment> segments = const []}) =>
    BuddyMessage(
      id: id,
      role: role,
      text: text,
      createdAt: at,
      kind: kind,
      translation: translation == null
          ? null
          : BuddyTranslation(text: translation, lang: lang, segments: segments),
    );

const BuddyStatus kFreeStatus = BuddyStatus(
  tier: 'FREE',
  buddyLimit: 1,
  buddyCount: 0,
  freeRepliesPerDay: 10,
  freeRepliesLeft: 7,
  coinsPerReply: 1,
);

/// Three avatar pictures as `buddy_avatars` would hold them.
const List<BuddyAvatarOption> kFakeAvatars = [
  BuddyAvatarOption(id: 'av_fox', url: 'https://img.test/fox.png', label: 'Fox', order: 1),
  BuddyAvatarOption(id: 'av_owl', url: 'https://img.test/owl.png', label: 'Owl', order: 2),
  BuddyAvatarOption(id: 'av_cat', url: 'https://img.test/cat.png', label: 'Cat', order: 3),
];

/// In-memory [BuddiesRepository]: streams are driven by the test.
class FakeBuddiesRepository implements BuddiesRepository {
  final buddies = StreamController<List<Buddy>>.broadcast();
  final buddy = StreamController<Buddy?>.broadcast();
  final newMessages = StreamController<List<BuddyMessage>>.broadcast();

  BuddyStatus status = kFreeStatus;
  BuddyMessagePage latest = const BuddyMessagePage(messages: [], hasMore: false);
  BuddyMessagePage older = const BuddyMessagePage(messages: [], hasMore: false);

  /// Answers to sendMessage, in order: a BuddySendResult or an error to throw.
  final List<Object> sendAnswers = [];
  final List<Map<String, String>> sent = [];

  /// The `align` flag of each sendMessage call (same order as [sent]).
  final List<bool?> aligns = [];
  final List<BuddySettings> created = [];
  Object? createError;
  final List<Map<String, Object?>> updates = [];
  final List<String?> forgotten = [];
  final List<bool> cleared = [];
  final List<String> deleted = [];
  DateTime? olderBefore;
  int _req = 0;

  /// Completes sendMessage only when set (typing indicator tests).
  Completer<void>? sendGate;

  /// What avatarOptions returns; set [avatarsError] to make it fail.
  List<BuddyAvatarOption> avatars = kFakeAvatars;
  Object? avatarsError;
  int avatarReads = 0;
  List<BuddyAvatarOption>? _avatarCache;

  @override
  List<BuddyAvatarOption>? get cachedAvatarOptions => _avatarCache;

  @override
  Future<List<BuddyAvatarOption>> avatarOptions({bool refresh = false}) async {
    if (_avatarCache != null && !refresh) return _avatarCache!;
    avatarReads++;
    if (avatarsError != null) throw avatarsError!;
    return _avatarCache = avatars;
  }

  @override
  Stream<List<Buddy>> watchBuddies(String uid) => buddies.stream;

  @override
  Stream<Buddy?> watchBuddy(String uid, String buddyId) => buddy.stream;

  @override
  Future<BuddyStatus> getStatus() async => status;

  @override
  Future<String> createBuddy(BuddySettings settings) async {
    if (createError != null) throw createError!;
    created.add(settings);
    return 'new-buddy';
  }

  @override
  Future<void> updateBuddy(String buddyId, Map<String, Object?> patch) async => updates.add(patch);

  @override
  Future<void> deleteBuddy(String buddyId) async => deleted.add(buddyId);

  @override
  Future<void> clearChat(String buddyId, {bool forgetMemory = false}) async =>
      cleared.add(forgetMemory);

  @override
  Future<void> forgetMemory(String buddyId, {String? factId}) async => forgotten.add(factId);

  @override
  Future<BuddySendResult> sendMessage({
    required String buddyId,
    required String text,
    required String requestId,
    bool? align,
  }) async {
    sent.add({'text': text, 'requestId': requestId});
    aligns.add(align);
    if (sendGate != null) await sendGate!.future;
    if (sendAnswers.isEmpty) {
      return BuddySendResult(
          reply: 'Reply to $text', kind: 'chat', charged: 'free', freeRepliesLeft: 5);
    }
    final a = sendAnswers.removeAt(0);
    if (a is BuddySendResult) return a;
    throw a;
  }

  @override
  Future<BuddyMessagePage> latestMessages(String uid, String buddyId, {int limit = 30}) async =>
      latest;

  @override
  Future<BuddyMessagePage> olderMessages(String uid, String buddyId,
      {required DateTime before, int limit = 30}) async {
    olderBefore = before;
    return older;
  }

  @override
  Stream<List<BuddyMessage>> watchNewMessages(String uid, String buddyId, {DateTime? after}) =>
      newMessages.stream;

  @override
  String newRequestId() => 'req-${++_req}-abcdef';

  Future<void> dispose() async {
    await buddies.close();
    await buddy.close();
    await newMessages.close();
  }
}

/// Records prompt calls instead of opening real dialogs / services.
class FakeBuddyPrompts extends BuddyPrompts {
  FakeBuddyPrompts({this.consentResult = true});

  final bool consentResult;
  final List<String> calls = [];
  final List<AppSound> sounds = [];

  @override
  Future<void> showUpgrade(BuildContext context,
      {required String uid, required int limit, String? tier}) async {
    calls.add('upgrade:$limit');
  }

  @override
  Future<void> showInsufficientCoins(BuildContext context,
      {required String uid, required int coins, int repliesPerCoin = 1}) async {
    calls.add(repliesPerCoin > 1 ? 'coins:$coins/$repliesPerCoin' : 'coins:$coins');
  }

  @override
  Future<bool> ensureAiConsent(BuildContext context, {required bool update}) async {
    calls.add('consent:$update');
    return consentResult;
  }

  @override
  void maybePromptAiConsent(BuildContext context) {}

  @override
  Future<void> report(BuildContext context,
      {required String uid,
      required String buddyId,
      required String messageId,
      required String text}) async {
    calls.add('report:$messageId');
  }

  @override
  void playSound(AppSound sound) => sounds.add(sound);

  @override
  Future<void> showError(BuildContext context, BuddyException e) async {
    calls.add('error:${e.kind.name}');
  }
}
