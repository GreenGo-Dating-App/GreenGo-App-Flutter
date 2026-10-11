import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/deep_link_service.dart';
import 'package:greengo_chat/features/referral/data/services/pending_referral_store.dart';
import 'package:greengo_chat/features/referral/data/services/referral_auto_redeemer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Invite links (/r/{CODE}): parsing, pending-code storage with expiry, and
/// the automatic (silent) redemption after sign-up.
void main() {
  group('invite link parsing', () {
    DeepLinkTarget? p(String s) => DeepLinkService.parse(Uri.parse(s));
    const ref = DeepLinkKind.referral;

    test('builds https://greengo-chat.web.app/r/{CODE}', () {
      expect(DeepLinkService.buildReferralLink(' abc234 '),
          'https://greengo-chat.web.app/r/ABC234');
    });

    test('universal link, custom scheme and the web hand-off', () {
      expect(p('https://greengo-chat.web.app/r/ABC234'),
          const DeepLinkTarget(ref, 'ABC234'));
      expect(p('https://greengo-chat.web.app/r/abc234'),
          const DeepLinkTarget(ref, 'ABC234'));
      expect(p('greengo://r/ABC234'), const DeepLinkTarget(ref, 'ABC234'));
      expect(p('https://greengo-chat.web.app/?link=%2Fr%2FABC234'),
          const DeepLinkTarget(ref, 'ABC234'));
      expect(p('https://greengo-chat.web.app/?link=/r/ABC234'),
          const DeepLinkTarget(ref, 'ABC234'));
    });

    test('rejects foreign hosts and malformed codes', () {
      expect(p('https://evil.example.com/r/ABC234'), isNull);
      expect(p('https://greengo-chat.web.app/r/AB'), isNull);
      expect(p('https://greengo-chat.web.app/r/ABC_234'), isNull);
      expect(p('https://greengo-chat.web.app/r/'), isNull);
    });

    test('a built invite link parses back to its code', () {
      final link = Uri.parse(DeepLinkService.buildReferralLink('XYZ789'));
      expect(DeepLinkService.parse(link),
          const DeepLinkTarget(DeepLinkKind.referral, 'XYZ789'));
    });

    test('a web launch with an invite link is stored, not navigated',
        () async {
      SharedPreferences.setMockInitialValues({});
      DeepLinkService.instance.referralStore = PendingReferralStore();
      DeepLinkService.instance.captureWebLaunchLink(
          Uri.parse('https://greengo-chat.web.app/?link=%2Fr%2FWEB234'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(DeepLinkService.instance.pendingTarget, isNull);
      expect((await PendingReferralStore().read())?.code, 'WEB234');
    });
  });

  group('PendingReferralStore', () {
    var now = DateTime(2026, 10, 11, 12);
    PendingReferralStore store() => PendingReferralStore(clock: () => now);

    setUp(() {
      now = DateTime(2026, 10, 11, 12);
      SharedPreferences.setMockInitialValues({});
    });

    test('saves a normalized code with its timestamp', () async {
      expect(await store().save(' abc234 '), isTrue);
      final p = await store().read();
      expect(p?.code, 'ABC234');
      expect(p?.capturedAt, now);
    });

    test('ignores malformed codes', () async {
      expect(await store().save('a'), isFalse);
      expect(await store().save('ABC-234'), isFalse);
      expect(await store().read(), isNull);
    });

    test('latest link wins', () async {
      await store().save('AAA222');
      await store().save('BBB333');
      expect((await store().read())?.code, 'BBB333');
    });

    test('expires (and is removed) after 30 days', () async {
      await store().save('ABC234');
      now = now.add(const Duration(days: 29, hours: 23));
      expect((await store().read())?.code, 'ABC234');
      now = now.add(const Duration(hours: 2));
      expect(await store().read(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(PendingReferralStore.codeKey), isFalse);
    });

    test('reads the keys the /r/ web page writes (web sign-ups)', () async {
      SharedPreferences.setMockInitialValues({
        PendingReferralStore.codeKey: 'WEB234',
        PendingReferralStore.capturedAtKey: now.millisecondsSinceEpoch,
      });
      expect((await store().read())?.code, 'WEB234');
    });

    test('clear removes it', () async {
      await store().save('ABC234');
      await store().clear();
      expect(await store().read(), isNull);
    });
  });

  group('ReferralAutoRedeemer', () {
    late List<String> calls;
    late Object? failure;
    String? uid;

    ReferralAutoRedeemer redeemer() => ReferralAutoRedeemer(
          store: PendingReferralStore(),
          currentUserId: () => uid,
          redeem: (code) async {
            calls.add(code);
            final f = failure;
            if (f != null) throw f;
          },
        );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      calls = [];
      failure = null;
      uid = 'newUser1';
    });

    test('no pending code: nothing is called', () async {
      expect(await redeemer().tryRedeem(), ReferralRedeemOutcome.none);
      expect(calls, isEmpty);
    });

    test('not signed in: keeps the code, calls nothing', () async {
      await PendingReferralStore().save('ABC234');
      uid = null;
      expect(await redeemer().tryRedeem(), ReferralRedeemOutcome.none);
      expect(calls, isEmpty);
      expect((await PendingReferralStore().read())?.code, 'ABC234');
    });

    test('success: redeems once and clears the code', () async {
      await PendingReferralStore().save('ABC234');
      final r = redeemer();
      expect(await r.tryRedeem(), ReferralRedeemOutcome.redeemed);
      expect(calls, ['ABC234']);
      expect(await PendingReferralStore().read(), isNull);
      expect(await r.tryRedeem(), ReferralRedeemOutcome.none);
      expect(calls, ['ABC234']);
    });

    test('concurrent triggers share one call', () async {
      await PendingReferralStore().save('ABC234');
      final r = redeemer();
      await Future.wait([r.tryRedeem(), r.tryRedeem(), r.tryRedeem()]);
      expect(calls, ['ABC234']);
    });

    for (final code in [
      'already-exists',
      'not-found',
      'failed-precondition',
      'invalid-argument',
      'permission-denied',
    ]) {
      test('terminal server error "$code" clears the code', () async {
        await PendingReferralStore().save('ABC234');
        failure = FirebaseFunctionsException(message: 'x', code: code);
        expect(await redeemer().tryRedeem(), ReferralRedeemOutcome.rejected);
        expect(await PendingReferralStore().read(), isNull);
      });
    }

    for (final f in <Object>[
      FirebaseFunctionsException(message: 'x', code: 'unavailable'),
      FirebaseFunctionsException(message: 'x', code: 'internal'),
      FirebaseFunctionsException(message: 'x', code: 'deadline-exceeded'),
      Exception('SocketException: no network'),
    ]) {
      test('network / transient error keeps the code for a retry ($f)',
          () async {
        await PendingReferralStore().save('ABC234');
        failure = f;
        expect(
            await redeemer().tryRedeem(), ReferralRedeemOutcome.retryLater);
        expect((await PendingReferralStore().read())?.code, 'ABC234');
        // Next trigger (e.g. home shell attaches again) retries and succeeds.
        failure = null;
        expect(await redeemer().tryRedeem(), ReferralRedeemOutcome.redeemed);
        expect(calls, ['ABC234', 'ABC234']);
      });
    }
  });
}
