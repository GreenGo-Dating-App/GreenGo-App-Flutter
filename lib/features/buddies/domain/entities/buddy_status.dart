import 'package:equatable/equatable.dart';

import 'buddy_message.dart';

/// `getBuddyStatus`: plan limits, today's free replies and the reply price.
///
/// Paid replies (2026-10-24): one coin buys [repliesPerCoin] replies
/// ([coinsPerReply] = 0.33 for 3). The first paid reply takes a coin and
/// leaves the rest as [replyCredits] (prepaid replies, never expire).
class BuddyStatus extends Equatable {
  const BuddyStatus({
    required this.tier,
    required this.buddyLimit,
    required this.buddyCount,
    required this.freeRepliesPerDay,
    required this.freeRepliesLeft,
    required this.coinsPerReply,
    int? repliesPerCoin,
    this.replyCredits = 0,
  }) : repliesPerCoin = repliesPerCoin ?? 1;

  factory BuddyStatus.fromMap(Map<String, dynamic> m) {
    int n(String k, int d) => (m[k] as num?)?.toInt() ?? d;
    final price = (m['coinsPerReply'] as num?) ?? 1;
    final perCoin = (m['repliesPerCoin'] as num?)?.toInt() ?? repliesPerCoinFor(price);
    return BuddyStatus(
      tier: (m['tier'] as String?) ?? 'FREE',
      buddyLimit: n('buddyLimit', 1),
      buddyCount: n('buddyCount', 0),
      freeRepliesPerDay: n('freeRepliesPerDay', 10),
      freeRepliesLeft: n('freeRepliesLeft', 0),
      coinsPerReply: price,
      repliesPerCoin: perCoin < 1 ? 1 : perCoin,
      replyCredits: n('replyCredits', 0),
    );
  }

  /// Replies one coin buys at [price] coins per reply (1 when a reply costs
  /// a coin or more).
  static int repliesPerCoinFor(num price) => price > 0 && price < 1 ? (1 / price).round() : 1;

  /// Effective tier as the server sees it: FREE, SILVER, GOLD, PLATINUM, TEST.
  final String tier;
  final int buddyLimit;
  final int buddyCount;
  final int freeRepliesPerDay;
  final int freeRepliesLeft;

  /// Price of one paid reply in coins (0.33 = 1 coin for 3 replies).
  final num coinsPerReply;
  final int repliesPerCoin;

  /// Prepaid replies left (already paid with a coin).
  final int replyCredits;

  bool get canCreateMore => buddyCount < buddyLimit;

  /// Coins a paid reply needs when no prepaid reply is left (whole coins).
  int get coinsNeeded => coinsPerReply <= 1 ? 1 : coinsPerReply.ceil();

  BuddyStatus copyWith({int? buddyCount, int? freeRepliesLeft, int? replyCredits}) => BuddyStatus(
        tier: tier,
        buddyLimit: buddyLimit,
        buddyCount: buddyCount ?? this.buddyCount,
        freeRepliesPerDay: freeRepliesPerDay,
        freeRepliesLeft: freeRepliesLeft ?? this.freeRepliesLeft,
        coinsPerReply: coinsPerReply,
        repliesPerCoin: repliesPerCoin,
        replyCredits: replyCredits ?? this.replyCredits,
      );

  @override
  List<Object?> get props => [
        tier,
        buddyLimit,
        buddyCount,
        freeRepliesPerDay,
        freeRepliesLeft,
        coinsPerReply,
        repliesPerCoin,
        replyCredits,
      ];
}

/// `sendBuddyMessage` result: one turn = the Buddy's 1-3 bubbles
/// ([replies]), charged once.
class BuddySendResult extends Equatable {
  const BuddySendResult({
    required this.reply,
    required this.kind,
    required this.charged,
    required this.freeRepliesLeft,
    this.replies = const <String>[],
    this.keywords = const <BuddyKeyword>[],
    this.coinBalance,
    this.replyCredits,
    this.translations = const <String?>[],
    this.userTranslation,
  });

  factory BuddySendResult.fromMap(Map<String, dynamic> m) => BuddySendResult(
        reply: (m['reply'] as String?) ?? '',
        replies: [
          if (m['replies'] is List)
            for (final r in m['replies'] as List)
              if (r is String && r.trim().isNotEmpty) r,
        ],
        // Aligned with the raw `replies` (same filter keeps them aligned).
        translations: [
          if (m['replies'] is List)
            for (var i = 0; i < (m['replies'] as List).length; i++)
              if ((m['replies'] as List)[i] case final String r when r.trim().isNotEmpty)
                _translationAt(m['translations'], i),
        ],
        userTranslation: _cleanTranslation(m['userTranslation']),
        keywords: BuddyKeyword.listFrom(m['keywords']),
        kind: (m['kind'] as String?) ?? 'chat',
        charged: (m['charged'] as String?) ?? 'none',
        freeRepliesLeft: (m['freeRepliesLeft'] as num?)?.toInt() ?? 0,
        coinBalance: (m['coinBalance'] as num?)?.toInt(),
        replyCredits: (m['replyCredits'] as num?)?.toInt(),
      );

  static String? _cleanTranslation(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

  static String? _translationAt(Object? list, int i) =>
      list is List && i < list.length ? _cleanTranslation(list[i]) : null;

  /// The server's translations of [replies] into the chat language (same
  /// order; null = none / already in that language).
  final List<String?> translations;

  /// The server's translation of the user's message (null = none).
  final String? userTranslation;

  /// All bubbles joined with new lines (older servers: the only reply).
  final String reply;

  /// The bubbles of this turn, in order (1-3). Empty from older servers and
  /// for safety replies: use [bubbles].
  final List<String> replies;

  /// Places the Buddy named in this turn.
  final List<BuddyKeyword> keywords;

  /// `chat` or `safety`.
  final String kind;

  /// `free`, `coin` (took a coin, left prepaid replies), `credit` (used a
  /// prepaid reply) or `none`.
  final String charged;
  final int freeRepliesLeft;
  final int? coinBalance;

  /// Prepaid replies left, when the server sent it.
  final int? replyCredits;

  /// What to show, in order: [replies], else [reply]. Anything that looks
  /// like raw JSON is never shown (the server already prevents it).
  List<String> get bubbles => [for (final (b, _) in turnBubbles) b];

  /// [bubbles] with their translation (null = none), aligned.
  List<(String, String?)> get turnBubbles {
    final list = replies.isNotEmpty
        ? [
            for (var i = 0; i < replies.length; i++)
              (replies[i], i < translations.length ? translations[i] : null),
          ]
        : [if (reply.trim().isNotEmpty) (reply, null)];
    return [for (final e in list) if (!looksLikeJson(e.$1)) e];
  }

  /// Same as [turnBubbles].
  List<(String, String?)> get bubblesWithTranslations => turnBubbles;

  static final RegExp _jsonStart = RegExp(r'^\s*[{\[]');
  static final RegExp _jsonKey = RegExp(r'"(messages|keywords|reply)"\s*:');

  /// A JSON object / array or a fragment with the reply keys.
  static bool looksLikeJson(String s) => _jsonStart.hasMatch(s) || _jsonKey.hasMatch(s);

  @override
  List<Object?> get props =>
      [
        reply,
        replies,
        keywords,
        kind,
        charged,
        freeRepliesLeft,
        coinBalance,
        replyCredits,
        translations,
        userTranslation,
      ];
}
