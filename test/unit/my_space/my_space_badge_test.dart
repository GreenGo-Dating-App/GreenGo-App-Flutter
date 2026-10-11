import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/my_space/data/my_space_badge.dart';

import '../../support/my_space_fixtures.dart';

void main() {
  setUp(MySpaceBadge.reset);

  test('counts requests + payments + today\'s sessions (distinct)', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 0);
    final repo = FakeMySpaceRepository(
      requests: 2,
      payments: 1,
      hostBookings: [
        testBooking(id: 'a', experienceId: 'x1', start: today),
        testBooking(id: 'b', experienceId: 'x1', start: today), // same session
        testBooking(id: 'c', experienceId: 'x2', start: today.add(const Duration(days: 9))),
      ],
    );
    await MySpaceBadge.refresh('me', repository: repo, force: true);
    expect(MySpaceBadge.count.value, 2 + 1 + 1);
  });

  test('cached for a short time unless forced', () async {
    final repo = FakeMySpaceRepository(requests: 1);
    await MySpaceBadge.refresh('me', repository: repo);
    expect(MySpaceBadge.count.value, 1);
    repo.requests = 5;
    await MySpaceBadge.refresh('me', repository: repo);
    expect(MySpaceBadge.count.value, 1, reason: 'cached');
    await MySpaceBadge.refresh('me', repository: repo, force: true);
    expect(MySpaceBadge.count.value, 5);
  });

  test('switching account clears the previous number immediately', () async {
    await MySpaceBadge.refresh('alice', repository: FakeMySpaceRepository(requests: 4));
    expect(MySpaceBadge.count.value, 4);
    final pending = MySpaceBadge.refresh('bob', repository: FakeMySpaceRepository(requests: 0));
    expect(MySpaceBadge.count.value, 0);
    await pending;
    expect(MySpaceBadge.count.value, 0);
  });

  test('a failure keeps the last good number; reset clears it', () async {
    await MySpaceBadge.refresh('me', repository: FakeMySpaceRepository(payments: 3));
    await MySpaceBadge.refresh('me',
        repository: FakeMySpaceRepository(failEvents: true), force: true);
    expect(MySpaceBadge.count.value, 3);
    MySpaceBadge.reset();
    expect(MySpaceBadge.count.value, 0);
  });
}
