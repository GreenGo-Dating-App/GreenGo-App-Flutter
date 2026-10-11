import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/referral/data/services/referral_service.dart';

/// Display mirror of functions/src/referral/referralRules.ts. The server is the
/// source of truth; these values must match it.
void main() {
  test('rules mirror the server: 50 coins, 1,000/month, 5/10/20', () {
    expect(ReferralService.referrerCoinReward, 50);
    expect(ReferralService.referrerMonthlyCap, 1000);
    expect(ReferralService.milestones.map((m) => m.count), [5, 10, 20]);
    expect(ReferralService.milestones.map((m) => m.tier), [
      ReferralMilestoneTier.silver,
      ReferralMilestoneTier.gold,
      ReferralMilestoneTier.platinum,
    ]);
  });

  group('ReferralProgress', () {
    ReferralProgress at(int n, [Set<int> granted = const {}]) =>
        ReferralProgress(
            invitedCount: n, coinsEarned: 0, milestonesGranted: granted);

    test('next milestone and remaining count', () {
      expect(at(0).nextMilestone!.count, 5);
      expect(at(0).remainingToNext, 5);
      expect(at(4).remainingToNext, 1);
      expect(at(5).nextMilestone!.count, 10);
      expect(at(7).remainingToNext, 3);
      expect(at(19).nextMilestone!.tier, ReferralMilestoneTier.platinum);
      expect(at(20).nextMilestone, isNull);
      expect(at(20).remainingToNext, 0);
    });

    test('unlocked = granted by the server or threshold reached', () {
      final silver = ReferralService.milestones.first;
      expect(at(4).isUnlocked(silver), isFalse);
      expect(at(5).isUnlocked(silver), isTrue);
      expect(at(0, {5}).isUnlocked(silver), isTrue);
    });

    test('fromMap parses the server doc and tolerates junk', () {
      final p = ReferralProgress.fromMap({
        'invitedCount': 12,
        'coinsEarned': 600,
        'milestonesGranted': [5, 10, 'x'],
        'milestonesFailed': [10],
      });
      expect(p.invitedCount, 12);
      expect(p.coinsEarned, 600);
      expect(p.milestonesGranted, {5});
      expect(ReferralProgress.fromMap(null).invitedCount, 0);
    });
  });
}
