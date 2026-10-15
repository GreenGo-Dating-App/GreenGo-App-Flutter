import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/discovery/presentation/discovery_refresh_limiter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('allows 10 manual refreshes a day, then refuses', () async {
    final l = DiscoveryRefreshLimiter(clock: () => DateTime(2026, 10, 14, 9));
    expect(await l.remaining('u1'), 10);
    for (var i = 9; i >= 0; i--) {
      expect(await l.tryConsume('u1'), i);
    }
    expect(await l.tryConsume('u1'), isNull);
    expect(await l.remaining('u1'), 0);
  });

  test('resets on the next day and drops the old counter', () async {
    var now = DateTime(2026, 10, 14, 23, 59);
    final l = DiscoveryRefreshLimiter(clock: () => now);
    for (var i = 0; i < 10; i++) {
      await l.tryConsume('u1');
    }
    expect(await l.tryConsume('u1'), isNull);
    now = DateTime(2026, 10, 15, 0, 1);
    expect(await l.tryConsume('u1'), 9);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('discovery_refresh_u1_')).length, 1);
  });

  test('each user has their own count', () async {
    final l = DiscoveryRefreshLimiter(clock: () => DateTime(2026, 10, 14));
    for (var i = 0; i < 10; i++) {
      await l.tryConsume('u1');
    }
    expect(await l.tryConsume('u1'), isNull);
    expect(await l.tryConsume('u2'), 9);
  });
}
