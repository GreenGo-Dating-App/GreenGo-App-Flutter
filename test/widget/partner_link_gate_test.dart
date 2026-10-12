import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/own_profile_store.dart';
import 'package:greengo_chat/core/utils/partner_link_gate.dart';
import 'package:greengo_chat/features/events/domain/entities/external_event.dart';
import 'package:greengo_chat/features/events/presentation/widgets/attraction_menu_dialog.dart';
import 'package:greengo_chat/features/events/presentation/widgets/event_message_card.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/user_experiences/domain/contact_info.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../support/profile_fixtures.dart';

/// Owner rule 2026-10-12:
///  * FREE users never see the "Open link" of Ticketmaster / Viator items
///    (attraction window, shared chat cards); Base or any paid tier does.
///    Other sources (Wikipedia / curated / Google) keep their link.
///  * No e-mail address / phone number in community event text.
void main() {
  const uid = 'u1';
  final future = DateTime.now().add(const Duration(days: 30));
  final l10n = lookupAppLocalizations(const Locale('en'));

  void seedFree() => OwnProfileStore.instance
      .seed(uid, (buildProfile(userId: uid) as ProfileModel).toJson());
  void seedBase() => OwnProfileStore.instance.seed(
      uid,
      (buildProfile(
              userId: uid,
              hasBaseMembership: true,
              baseMembershipEndDate: future) as ProfileModel)
          .toJson());

  ExternalEvent item(String source, String url) => ExternalEvent(
      id: 'x1', source: source, title: 'Item', bookingUrl: url);

  Future<void> openWindow(WidgetTester tester, ExternalEvent e) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showAttractionMenu(context, event: e, currentUserId: uid),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder openLink() => find.textContaining(l10n.attractionOpenLink);

  setUp(() => OwnProfileStore.instance.reset());
  tearDown(() => OwnProfileStore.instance.reset());

  group('attraction window', () {
    testWidgets('free user: no Open link for Viator / Ticketmaster',
        (tester) async {
      seedFree();
      await openWindow(
          tester, item('viator', 'https://www.viator.com/tours/x'));
      expect(openLink(), findsNothing);
      // The rest of the window is still there.
      expect(find.text(l10n.attractionShareChat), findsOneWidget);

      await tester.tapAt(const Offset(5, 5)); // dismiss
      await tester.pumpAndSettle();
      await openWindow(
          tester, item('ticketmaster', 'https://www.ticketmaster.com/e/1'));
      expect(openLink(), findsNothing);
    });

    testWidgets('free user still gets other sources\' link', (tester) async {
      seedFree();
      await openWindow(
          tester, item('geoapify', 'https://www.wikidata.org/wiki/Q1'));
      expect(openLink(), findsOneWidget);
    });

    testWidgets('Base member sees the partner link', (tester) async {
      seedBase();
      await openWindow(
          tester, item('viator', 'https://www.viator.com/tours/x'));
      expect(openLink(), findsOneWidget);
    });

    testWidgets('unknown own profile: hidden (fails closed)', (tester) async {
      await openWindow(
          tester, item('viator', 'https://www.viator.com/tours/x'));
      expect(openLink(), findsNothing);
    });
  });

  group('shared chat card', () {
    Future<void> tapCard(WidgetTester tester, Map<String, dynamic> meta) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: EventMessageCard(metadata: meta, currentUserId: uid)),
      ));
      await tester.tap(find.byType(EventMessageCard));
      await tester.pumpAndSettle();
    }

    const viator = {
      'eventTitle': 'Tour',
      'externalUrl': 'https://www.viator.com/tours/x',
      'externalSource': 'Viator',
    };

    testWidgets('free: no Open link on a partner share', (tester) async {
      seedFree();
      await tapCard(tester, viator);
      expect(find.text(l10n.attractionOpenLink), findsNothing);
      expect(find.text(l10n.attractionShareChat), findsOneWidget);
    });

    testWidgets('Base: Open link on a partner share', (tester) async {
      seedBase();
      await tapCard(tester, viator);
      expect(find.text(l10n.attractionOpenLink), findsOneWidget);
    });

    testWidgets('free: a non-partner share keeps its link', (tester) async {
      seedFree();
      await tapCard(tester, const {
        'eventTitle': 'Museum',
        'externalUrl': 'https://www.wikidata.org/wiki/Q1',
        'externalSource': 'Wikipedia',
      });
      expect(find.text(l10n.attractionOpenLink), findsOneWidget);
    });
  });

  test('isPartnerShare matches by label or host', () {
    expect(PartnerLinkGate.isPartnerShare(sourceLabel: 'Ticketmaster'), isTrue);
    expect(
        PartnerLinkGate.isPartnerShare(
            url: 'https://www.ticketmaster.co.uk/event/1'),
        isTrue);
    expect(PartnerLinkGate.isPartnerShare(url: 'https://viator.com/x'), isTrue);
    expect(
        PartnerLinkGate.isPartnerShare(
            url: 'https://www.wikidata.org/wiki/Q1', sourceLabel: 'Wikipedia'),
        isFalse);
  });

  group('ContactInfoDetector.hasEmailOrPhone (events)', () {
    test('catches e-mails and phone numbers', () {
      for (final t in [
        'write to maria.silva@gmail.com',
        'Call +55 (11) 98765-4321',
        'whatsapp 11987654321',
        'tel 06 1234 5678',
      ]) {
        expect(ContactInfoDetector.hasEmailOrPhone(t), isTrue, reason: t);
      }
    });

    test('leaves normal event text alone', () {
      for (final t in [
        'Meet at 18:30 on 12/10/2026, gate 3',
        'Language exchange PT-EN, 2 hours, 20 people max',
        'Rua Augusta 1500, 01304-001 São Paulo',
        '@ the park',
        null,
      ]) {
        expect(ContactInfoDetector.hasEmailOrPhone(t), isFalse, reason: t);
      }
    });
  });
}
