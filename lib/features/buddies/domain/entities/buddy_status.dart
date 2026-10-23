import 'package:equatable/equatable.dart';

/// `getBuddyStatus`: plan limits and today's free replies.
class BuddyStatus extends Equatable {
  const BuddyStatus({
    required this.tier,
    required this.buddyLimit,
    required this.buddyCount,
    required this.freeRepliesPerDay,
    required this.freeRepliesLeft,
    required this.coinsPerReply,
  });

  factory BuddyStatus.fromMap(Map<String, dynamic> m) {
    int n(String k, int d) => (m[k] as num?)?.toInt() ?? d;
    return BuddyStatus(
      tier: (m['tier'] as String?) ?? 'FREE',
      buddyLimit: n('buddyLimit', 1),
      buddyCount: n('buddyCount', 0),
      freeRepliesPerDay: n('freeRepliesPerDay', 10),
      freeRepliesLeft: n('freeRepliesLeft', 0),
      coinsPerReply: n('coinsPerReply', 1),
    );
  }

  /// Effective tier as the server sees it: FREE, SILVER, GOLD, PLATINUM, TEST.
  final String tier;
  final int buddyLimit;
  final int buddyCount;
  final int freeRepliesPerDay;
  final int freeRepliesLeft;
  final int coinsPerReply;

  bool get canCreateMore => buddyCount < buddyLimit;

  BuddyStatus copyWith({int? buddyCount, int? freeRepliesLeft}) => BuddyStatus(
        tier: tier,
        buddyLimit: buddyLimit,
        buddyCount: buddyCount ?? this.buddyCount,
        freeRepliesPerDay: freeRepliesPerDay,
        freeRepliesLeft: freeRepliesLeft ?? this.freeRepliesLeft,
        coinsPerReply: coinsPerReply,
      );

  @override
  List<Object?> get props =>
      [tier, buddyLimit, buddyCount, freeRepliesPerDay, freeRepliesLeft, coinsPerReply];
}

/// `sendBuddyMessage` result.
class BuddySendResult extends Equatable {
  const BuddySendResult({
    required this.reply,
    required this.kind,
    required this.charged,
    required this.freeRepliesLeft,
    this.coinBalance,
  });

  factory BuddySendResult.fromMap(Map<String, dynamic> m) => BuddySendResult(
        reply: (m['reply'] as String?) ?? '',
        kind: (m['kind'] as String?) ?? 'chat',
        charged: (m['charged'] as String?) ?? 'none',
        freeRepliesLeft: (m['freeRepliesLeft'] as num?)?.toInt() ?? 0,
        coinBalance: (m['coinBalance'] as num?)?.toInt(),
      );

  final String reply;

  /// `chat` or `safety`.
  final String kind;

  /// `free`, `coin` or `none`.
  final String charged;
  final int freeRepliesLeft;
  final int? coinBalance;

  @override
  List<Object?> get props => [reply, kind, charged, freeRepliesLeft, coinBalance];
}
