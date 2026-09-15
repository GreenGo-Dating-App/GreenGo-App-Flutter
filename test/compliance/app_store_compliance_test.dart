@Tags(['compliance'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/product_catalog.dart';
import 'package:greengo_chat/features/coins/domain/entities/coin_balance.dart';
import 'package:greengo_chat/features/coins/domain/entities/coin_package.dart';

/// App Store compliance invariants.
///
/// GreenGo was rejected three times over (submission b9c4cdc6, 09 Sep 2026)
/// for things that were plainly visible in the source: a coupon field that
/// unlocked paid tiers, purchased coins that expired, product IDs that had
/// drifted from App Store Connect. None of it was caught because nothing
/// checked. These tests are that check.
///
/// They are deliberately source-level where the invariant is "this must not
/// exist anywhere" — a widget test can only prove a screen it builds is clean,
/// while a repository scan proves the whole app is.
void main() {
  final libDir = Directory('lib');
  late List<File> dartFiles;

  setUpAll(() {
    dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // Generated localisations legitimately contain historical keys.
        .where((f) => !f.path.contains('generated'))
        .toList();
    expect(dartFiles, isNotEmpty, reason: 'run this from the package root');
  });

  group('Guideline 3.1.1 — no non-IAP unlock mechanism', () {
    test('no code-redemption widget or datasource exists', () {
      const forbiddenFiles = [
        'coupon_code_widget.dart',
        'pending_signup_coupon.dart',
        'pending_signup_referral.dart',
      ];
      final offenders = <String>[];
      for (final f in dartFiles) {
        final name = f.uri.pathSegments.last;
        if (forbiddenFiles.contains(name)) offenders.add(f.path);
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Code redemption unlocks paid functionality outside IAP. '
            'These files were removed in v4.0.0 and must not come back.',
      );
    });

    test('no client code calls a redemption callable', () {
      // The Cloud Functions stay deployed for server-side/admin use; what must
      // never exist again is a CLIENT path that reaches them.
      final forbidden = RegExp(
        r"""httpsCallable\(\s*['"](redeemCoupon|validateCoupon|redeemReferral)['"]""",
      );
      final offenders = <String>[];
      for (final f in dartFiles) {
        if (forbidden.hasMatch(f.readAsStringSync())) offenders.add(f.path);
      }
      expect(offenders, isEmpty,
          reason: 'A client must not be able to redeem a code.');
    });

    test('no promo-code lookup survives', () {
      final forbidden = RegExp(r"getPromotionByCode|ApplyPromoCode");
      final offenders = <String>[];
      for (final f in dartFiles) {
        if (forbidden.hasMatch(f.readAsStringSync())) offenders.add(f.path);
      }
      expect(offenders, isEmpty,
          reason: 'Looking a promotion up BY CODE is a redemption mechanism.');
    });
  });

  group('Guideline 3.1.1 — purchased currency never expires', () {
    test('CoinBatch carries no expiry field', () {
      final source =
          File('lib/features/coins/domain/entities/coin_balance.dart')
              .readAsStringSync();
      expect(source.contains('expirationDate'), isFalse,
          reason: 'Apple: "Purchased credits or currencies ... may never expire."');
      expect(source.contains('isExpired'), isFalse);
      expect(source.contains('daysUntilExpiration'), isFalse);
    });

    test('no coin balance writes an expiry to Firestore', () {
      final offenders = <String>[];
      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        if (src.contains("'expirationDate':")) offenders.add(f.path);
      }
      expect(offenders, isEmpty,
          reason: 'Writing an expiry re-creates the violation in the data.');
    });

    test('every coin in a balance is spendable regardless of age', () {
      final ancient = DateTime.now().subtract(const Duration(days: 4000));
      final balance = CoinBalance(
        userId: 'u1',
        totalCoins: 500,
        earnedCoins: 0,
        purchasedCoins: 500,
        giftedCoins: 0,
        spentCoins: 0,
        lastUpdated: DateTime.now(),
        coinBatches: [
          CoinBatch(
            batchId: 'b1',
            initialCoins: 500,
            remainingCoins: 500,
            source: CoinSource.purchase,
            acquiredDate: ancient,
          ),
        ],
      );
      expect(balance.availableCoins, 500);
      expect(balance.hasEnoughCoins(500), isTrue);
    });

    test('coins granted without a batch are still spendable', () {
      // Several Cloud Functions credit with a bare totalCoins increment.
      final balance = CoinBalance(
        userId: 'u1',
        totalCoins: 250,
        earnedCoins: 250,
        purchasedCoins: 0,
        giftedCoins: 0,
        spentCoins: 0,
        lastUpdated: DateTime.now(),
      );
      expect(balance.availableCoins, 250);
    });
  });

  group('Guideline 2.1(b) — store catalogue', () {
    late Map<String, dynamic> catalogue;

    setUpAll(() {
      catalogue = jsonDecode(File('tool/store_products.json').readAsStringSync())
          as Map<String, dynamic>;
    });

    test('canonical subscription IDs match the submitted catalogue', () {
      final expected = (catalogue['subscriptions']
              as Map<String, dynamic>)['canonical'] as List<dynamic>;
      expect(ProductCatalog.canonicalIds, expected.cast<String>(),
          reason: 'A drifted product ID fails only at runtime, in front of a '
              'reviewer. tool/store_products.json is the source of truth.');
    });

    test('coin pack product IDs match the submitted catalogue', () {
      final expected = (catalogue['consumables']
              as Map<String, dynamic>)['ios'] as List<dynamic>;
      final actual =
          CoinPackages.standardPackages.map((p) => p.productId).toList();
      expect(actual, expected.cast<String>());
    });

    test('the catalogue really is 11 products', () {
      final subs = (catalogue['subscriptions']
              as Map<String, dynamic>)['ios'] as List<dynamic>;
      final coins = (catalogue['consumables']
              as Map<String, dynamic>)['ios'] as List<dynamic>;
      expect(subs.length + coins.length, catalogue['expectedTotal']);
    });
  });

  group('Guideline 2.1(b) — no developer-facing store errors', () {
    test('the shop never names a product ID or a store console on screen', () {
      // Comments legitimately discuss App Store Connect; only what can REACH
      // the screen matters, so strip comments before scanning.
      final shop = _stripDartComments(
        File('lib/features/coins/presentation/screens/coin_shop_screen.dart')
            .readAsStringSync(),
      );

      // These strings were what the reviewer actually saw.
      for (final phrase in [
        'not found in \$storeName',
        'App Store Connect',
        'Google Play Console',
        'Make sure the product is configured',
        'Add your account as a tester',
      ]) {
        expect(shop.contains(phrase), isFalse,
            reason: 'Developer-facing text "$phrase" must never reach the UI.');
      }
    });

    test('the shop shows a localized fallback instead', () {
      final shop =
          File('lib/features/coins/presentation/screens/coin_shop_screen.dart')
              .readAsStringSync();
      expect(shop.contains('shopTemporarilyUnavailable'), isTrue);
      expect(shop.contains('_isPurchasable('), isTrue,
          reason: 'Unavailable products must be hidden, not rendered as '
              'buttons that are guaranteed to fail.');
    });
  });

  group('Guidelines 1.2.1 / 4.7.5 — age assurance', () {
    late String rules;

    setUpAll(() {
      rules = File('firestore.rules').readAsStringSync();
    });

    test('publishing to a community requires a verified age', () {
      // Client-side gating is a courtesy; this is the enforcement.
      expect(rules.contains('function isAgeVerified()'), isTrue);
      final canPost = rules.substring(
        rules.indexOf('function canPostChat()'),
        rules.indexOf('function canWriteTips()'),
      );
      expect(canPost.contains('isAgeVerified()'), isTrue,
          reason: 'canPostChat must require a verified age.');
    });

    test('a user cannot mark their own profile age-verified', () {
      // Without this guard the whole gate is decorative: a user could set the
      // flag on their own profile document and publish freely.
      // Matching the guard as two fragments rather than one multi-line
      // string keeps this robust to reformatting of the rules file.
      final updateRule = rules.substring(
        rules.indexOf('allow update: if (isOwner(profileId)'),
        rules.indexOf('allow delete: if isOwner(profileId)'),
      );
      expect(
        updateRule.contains("request.resource.data.get('isAgeVerified', false)") &&
            updateRule.contains("resource.data.get('isAgeVerified', false)"),
        isTrue,
        reason: 'profile update must hold isAgeVerified immutable.',
      );
    });

    test('a recreated profile cannot assert privileged flags', () {
      // delete + create was a way around the update guard.
      final createRule = rules.substring(
        rules.indexOf('allow create: if isOwner(profileId)'),
        rules.indexOf('allow update: if (isOwner(profileId)'),
      );
      for (final flag in ['isAdmin', 'isBanned', 'isAgeVerified']) {
        expect(createRule.contains("'$flag'"), isTrue,
            reason: 'profile create must refuse a self-asserted $flag.');
      }
    });

    test('identity documents are write-only in Storage', () {
      final storage = File('storage.rules').readAsStringSync();
      final block = storage.substring(
        storage.indexOf('match /age_verification/'),
      );
      expect(block.contains('allow read: if false;'), isTrue,
          reason: 'Nobody should be able to read back an identity document.');
    });
  });

  group('Guideline 1.2 — user-generated content safety', () {
    // Every screen that shows content authored by someone else must offer a
    // way to report it and to block its author. Group chat, event chat and
    // video discovery all shipped without one; this list is what stops the
    // next surface doing the same.
    const ugcSurfaces = <String>[
      'lib/features/chat/presentation/screens/chat_screen.dart',
      'lib/features/chat/presentation/screens/group_chat_screen.dart',
      'lib/features/events/presentation/screens/event_chat_screen.dart',
      'lib/features/communities/presentation/screens/community_detail_screen.dart',
      'lib/features/discovery/presentation/screens/profile_detail_screen.dart',
      'lib/features/video_profiles/presentation/screens/video_discovery_screen.dart',
    ];

    test('every UGC surface offers report and block', () {
      final missing = <String>[];
      for (final path in ugcSurfaces) {
        final file = File(path);
        if (!file.existsSync()) {
          missing.add('$path (file not found)');
          continue;
        }
        final src = file.readAsStringSync();
        // Either form counts: the imperative sheet, the AppBar overflow
        // widget, or the community wrapper around the sheet.
        final hasReport = src.contains('showReportBlockSheet') ||
            src.contains('showCommunityReportSheet') ||
            src.contains('SafetyActionsMenu') ||
            src.contains('ReportUser');
        if (!hasReport) missing.add(path);
      }
      expect(missing, isEmpty,
          reason: 'These screens show other people content with no way to '
              'report it. Guideline 1.2 requires one on every such surface.');
    });

    test('the shared sheet offers the underage reason', () {
      // 1.2.1 makes under-age content a first-class concern, so it must be a
      // selectable reason rather than buried under "Other".
      final sheet = File(
              'lib/features/safety/presentation/widgets/report_block_sheet.dart')
          .readAsStringSync();
      expect(sheet.contains('chatReportReasonUnderage'), isTrue);
    });
  });

  group('Video chat was removed in v4.0.0', () {
    test('no tier advertises a video chat capability', () {
      final offenders = <String>[];
      for (final f in dartFiles) {
        if (f.readAsStringSync().contains('canUseVideoChat')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'Selling a subscription benefit the app does not ship is a '
              'Guideline 2.3 / 3.1.2(c) problem.');
    });
  });
}

/// Removes `//` line comments and `/* */` block comments so a source scan
/// tests what the app can SHOW, not what its authors wrote about it.
String _stripDartComments(String source) {
  final withoutBlocks = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return withoutBlocks
      .split('\n')
      .map((line) {
        final idx = line.indexOf('//');
        if (idx == -1) return line;
        // Keep the line if the // sits inside a string literal.
        final before = line.substring(0, idx);
        final quotes =
            "'".allMatches(before).length + '"'.allMatches(before).length;
        return quotes.isOdd ? line : before;
      })
      .join('\n');
}
