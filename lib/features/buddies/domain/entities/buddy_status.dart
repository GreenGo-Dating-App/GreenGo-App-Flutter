import 'package:equatable/equatable.dart';

/// `getBuddyStatus`: plan limits, today's free replies and the reply price.
///
/// Paid replies (2026-10-24): one coin buys [repliesPerCoin] replies
/// ([coinsPerReply] = 0.2 for 5). The first paid reply takes a coin and
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

  /// Price of one paid reply in coins (0.2 = 1 coin for 5 replies).
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

/// `sendBuddyMessage` result.
class BuddySendResult extends Equatable {
  const BuddySendResult({
    required this.reply,
    required this.kind,
    required this.charged,
    required this.freeRepliesLeft,
    this.coinBalance,
    this.replyCredits,
  });

  factory BuddySendResult.fromMap(Map<String, dynamic> m) => BuddySendResult(
        reply: (m['reply'] as String?) ?? '',
        kind: (m['kind'] as String?) ?? 'chat',
        charged: (m['charged'] as String?) ?? 'none',
        freeRepliesLeft: (m['freeRepliesLeft'] as num?)?.toInt() ?? 0,
        coinBalance: (m['coinBalance'] as num?)?.toInt(),
        replyCredits: (m['replyCredits'] as num?)?.toInt(),
      );

  final String reply;

  /// `chat` or `safety`.
  final String kind;

  /// `free`, `coin` (took a coin, left prepaid replies), `credit` (used a
  /// prepaid reply) or `none`.
  final String charged;
  final int freeRepliesLeft;
  final int? coinBalance;

  /// Prepaid replies left, when the server sent it.
  final int? replyCredits;

  @override
  List<Object?> get props => [reply, kind, charged, freeRepliesLeft, coinBalance, replyCredits];
}
