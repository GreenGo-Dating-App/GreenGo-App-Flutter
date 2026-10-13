import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Outcome of [FreeChatService.claim].
enum FreeChatStatus {
  /// Base or a paid tier: no daily limit.
  unlimited,

  /// One of today's free chats (newly added or already on the list).
  allowed,

  /// Today's free chats are used up.
  limitReached,

  /// Not a free-chat conversation (group, support, unknown) or the call failed.
  unavailable,
}

class FreeChatClaim {
  const FreeChatClaim(this.status,
      {this.used = 0, this.limit = 3, this.added = false});
  final FreeChatStatus status;
  final int used;
  final int limit;

  /// True when this claim used up a new free chat (show the counter once).
  final bool added;

  bool get canSend =>
      status == FreeChatStatus.unlimited || status == FreeChatStatus.allowed;
}

/// Free chats without Base: an account with no plan may chat with 3 people
/// per UTC day (owner rule 2026-10-13). The server (`claimFreeChat`,
/// functions/src/entitlements/freeChat.ts) keeps the list and the Firestore
/// rules enforce it; this only asks once per conversation per day.
class FreeChatService {
  FreeChatService._({Future<Map<String, dynamic>> Function(String)? call})
      : _call = call ?? _callServer;

  static final FreeChatService instance = FreeChatService._();

  @visibleForTesting
  factory FreeChatService.test(
          Future<Map<String, dynamic>> Function(String) call) =>
      FreeChatService._(call: call);

  final Future<Map<String, dynamic>> Function(String conversationId) _call;

  /// Conversations already allowed today (UTC day [_day]).
  final Set<String> _allowedToday = {};
  int _day = -1;

  static int _utcDay(DateTime now) =>
      now.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  static Future<Map<String, dynamic>> _callServer(String conversationId) async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('claimFreeChat',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 15)))
        .call<Map<String, dynamic>>({'conversationId': conversationId});
    return Map<String, dynamic>.from(res.data);
  }

  Future<FreeChatClaim> claim(String conversationId, {DateTime? now}) async {
    final day = _utcDay(now ?? DateTime.now());
    if (day != _day) {
      _day = day;
      _allowedToday.clear();
    }
    if (_allowedToday.contains(conversationId)) {
      return const FreeChatClaim(FreeChatStatus.allowed);
    }
    try {
      final r = await _call(conversationId);
      final limit = (r['limit'] as num?)?.toInt() ?? 3;
      final used = (r['used'] as num?)?.toInt() ?? 0;
      if (r['unlimited'] == true) {
        return FreeChatClaim(FreeChatStatus.unlimited, limit: limit);
      }
      if (r['allowed'] == true) {
        _allowedToday.add(conversationId);
        return FreeChatClaim(FreeChatStatus.allowed,
            used: used, limit: limit, added: r['added'] == true);
      }
      return FreeChatClaim(FreeChatStatus.limitReached,
          used: used, limit: limit);
    } catch (e) {
      debugPrint('claimFreeChat failed: $e');
      return const FreeChatClaim(FreeChatStatus.unavailable);
    }
  }
}
