import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/free_chat_service.dart';
import 'package:greengo_chat/core/services/tier_entitlements.dart';

void main() {
  final day1 = DateTime.utc(2026, 10, 13, 15);
  final day2 = DateTime.utc(2026, 10, 14, 1);

  test('free accounts chat with 3 people a day', () {
    expect(TierEntitlements.freeDailyChats, 3);
  });

  test('a conversation allowed today is not asked for again', () async {
    var calls = 0;
    final s = FreeChatService.test((id) async {
      calls++;
      return {'allowed': true, 'unlimited': false, 'used': 1, 'limit': 3, 'added': true};
    });
    final first = await s.claim('c1', now: day1);
    expect(first.status, FreeChatStatus.allowed);
    expect(first.added, isTrue);
    expect(first.used, 1);
    final again = await s.claim('c1', now: day1);
    expect(again.canSend, isTrue);
    expect(again.added, isFalse);
    expect(calls, 1);
    // A new UTC day asks the server again.
    await s.claim('c1', now: day2);
    expect(calls, 2);
  });

  test('the 4th person is refused', () async {
    final s = FreeChatService.test((id) async =>
        {'allowed': false, 'unlimited': false, 'used': 3, 'limit': 3});
    final r = await s.claim('c4', now: day1);
    expect(r.status, FreeChatStatus.limitReached);
    expect(r.canSend, isFalse);
    expect(r.limit, 3);
  });

  test('members are unlimited and a failed call falls back to the gate', () async {
    final member = FreeChatService.test(
        (id) async => {'allowed': true, 'unlimited': true, 'limit': 3, 'used': 0});
    expect((await member.claim('c1', now: day1)).status, FreeChatStatus.unlimited);
    final broken = FreeChatService.test((id) async => throw Exception('offline'));
    final r = await broken.claim('c1', now: day1);
    expect(r.status, FreeChatStatus.unavailable);
    expect(r.canSend, isFalse);
  });
}
