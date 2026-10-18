// Buyer <-> organizer chat (2026-10-17): "Message the organizer / host"
// visibility, the server-verified buyer exemption vs the normal capped
// connect flow, the topic chip / list label and the `?chat=1` deep link.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/deep_link_service.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation_listing_context.dart';
import 'package:greengo_chat/features/chat/presentation/listing_chat.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/conversation_card.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/listing_chat_widgets.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

const _me = 'buyer1';
const _org = 'organizer1';

const _event = ListingChatRef(
  type: ConversationListingContext.event,
  id: 'ev1',
  title: 'Samba night',
  organizerId: _org,
);
const _experience = ListingChatRef(
  type: ConversationListingContext.experience,
  id: 'x1',
  title: 'Cooking class',
  organizerId: _org,
);

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: Center(child: child)),
    );

/// Records which path the flow took.
class _Recorder {
  final known = <Map<String, Object?>>[];
  final connect = <Map<String, Object?>>[];

  ListingChatFlow flow(Future<ListingChatAccess> Function(ListingChatRef) verify) =>
      ListingChatFlow(
        verify: verify,
        openKnown: (context,
            {required currentUserId,
            required organizerId,
            required conversationId,
            listingContext}) async {
          known.add({
            'uid': currentUserId,
            'organizer': organizerId,
            'conversation': conversationId,
            'context': listingContext,
          });
        },
        openConnect: (context,
            {required currentUserId,
            required otherUserId,
            businessInquiry,
            listingContext}) async {
          connect.add({
            'uid': currentUserId,
            'other': otherUserId,
            'business': businessInquiry,
            'context': listingContext,
          });
        },
      );
}

void main() {
  group('ListingChatButton visibility', () {
    testWidgets('event: "Message the organizer" for a visitor', (t) async {
      await t.pumpWidget(_app(const ListingChatButton(listing: _event, currentUserId: _me)));
      expect(find.text('Message the organizer'), findsOneWidget);
    });

    testWidgets('experience: "Message the host"', (t) async {
      await t.pumpWidget(_app(const ListingChatButton(listing: _experience, currentUserId: _me)));
      expect(find.text('Message the host'), findsOneWidget);
    });

    testWidgets('hidden for the organizer / host themselves', (t) async {
      await t.pumpWidget(_app(const ListingChatButton(listing: _event, currentUserId: _org)));
      expect(find.byKey(const ValueKey('listing-chat-button')), findsNothing);
      await t.pumpWidget(_app(const ListingChatButton(
          listing: _event, currentUserId: 'coOwner', isOrganizer: true)));
      expect(find.byKey(const ValueKey('listing-chat-button')), findsNothing);
    });

    testWidgets('hidden when nobody is signed in', (t) async {
      await t.pumpWidget(_app(const ListingChatButton(listing: _event, currentUserId: '')));
      expect(find.byKey(const ValueKey('listing-chat-button')), findsNothing);
    });
  });

  group('ListingChatFlow', () {
    testWidgets('verified ticket holder: opens the server conversation, never the capped connect gate',
        (t) async {
      final r = _Recorder();
      final flow = r.flow((_) async => const ListingChatAccess(
            buyer: true,
            organizerId: _org,
            businessInquiry: false,
            conversationId: 'conv9',
            context: ConversationListingContext(
                type: 'event', id: 'ev1', title: 'Samba night', buyer: true, buyerId: _me),
          ));
      await t.pumpWidget(_app(ListingChatButton(listing: _event, currentUserId: _me, flow: flow)));
      await t.tap(find.byKey(const ValueKey('listing-chat-button')));
      await t.pumpAndSettle();
      expect(r.connect, isEmpty, reason: 'buyers bypass the tier gate / daily cap');
      expect(r.known, hasLength(1));
      expect(r.known.single['conversation'], 'conv9');
      expect(r.known.single['organizer'], _org);
      expect((r.known.single['context']! as ConversationListingContext).id, 'ev1');
    });

    testWidgets('before buying: the normal connect flow (cap applies) with the topic, never buyer',
        (t) async {
      final r = _Recorder();
      final flow = r.flow((_) async => const ListingChatAccess(
            buyer: false,
            organizerId: _org,
            businessInquiry: true,
            context: ConversationListingContext(type: 'experience', id: 'x1', title: 'Cooking class'),
          ));
      await t.pumpWidget(_app(ListingChatButton(listing: _experience, currentUserId: _me, flow: flow)));
      await t.tap(find.byKey(const ValueKey('listing-chat-button')));
      await t.pumpAndSettle();
      expect(r.known, isEmpty);
      expect(r.connect, hasLength(1));
      final c = r.connect.single;
      expect(c['other'], _org);
      expect(c['business'], true);
      final ctx = c['context']! as ConversationListingContext;
      expect(ctx.id, 'x1');
      expect(ctx.buyer, isFalse);
    });

    testWidgets('a client-side "buyer" without a server conversation is NOT trusted', (t) async {
      final r = _Recorder();
      final flow = r.flow((_) async => const ListingChatAccess(
            buyer: true, organizerId: _org, businessInquiry: false));
      await t.pumpWidget(_app(ListingChatButton(listing: _event, currentUserId: _me, flow: flow)));
      await t.tap(find.byKey(const ValueKey('listing-chat-button')));
      await t.pumpAndSettle();
      expect(r.known, isEmpty);
      expect(r.connect, hasLength(1));
    });

    testWidgets('server unreachable: falls back to the capped connect flow with the listing',
        (t) async {
      final r = _Recorder();
      final flow = r.flow((_) async => throw Exception('unavailable'));
      await t.pumpWidget(_app(ListingChatButton(listing: _event, currentUserId: _me, flow: flow)));
      await t.tap(find.byKey(const ValueKey('listing-chat-button')));
      await t.pumpAndSettle();
      expect(r.known, isEmpty);
      expect(r.connect.single['other'], _org);
      expect(r.connect.single['business'], isNull);
      expect((r.connect.single['context']! as ConversationListingContext).title, 'Samba night');
    });

    testWidgets('own listing / blocked: nothing opens', (t) async {
      final r = _Recorder();
      final flow = r.flow((_) async => throw const ListingChatRefused('blocked'));
      await t.pumpWidget(_app(ListingChatButton(listing: _event, currentUserId: _me, flow: flow)));
      await t.tap(find.byKey(const ValueKey('listing-chat-button')));
      await t.pumpAndSettle();
      expect(r.known, isEmpty);
      expect(r.connect, isEmpty);
    });
  });

  group('topic chip and list label', () {
    final ctx = ConversationListingContext(
      type: 'event',
      id: 'ev1',
      title: 'Samba night',
      startAt: DateTime(2026, 11, 20, 20),
      buyer: true,
      buyerId: _me,
    );

    testWidgets('chip: "About: <title> · <date>"; the organizer sees "Ticket holder"', (t) async {
      await t.pumpWidget(_app(ListingContextChip(listingContext: ctx, currentUserId: _org)));
      expect(find.textContaining('About: Samba night · '), findsOneWidget);
      expect(find.textContaining('Nov 20, 2026'), findsOneWidget);
      expect(find.text('Ticket holder'), findsOneWidget);
    });

    testWidgets('chip: the buyer does not see their own tag', (t) async {
      await t.pumpWidget(_app(ListingContextChip(listingContext: ctx, currentUserId: _me)));
      expect(find.byKey(const ValueKey('listing-buyer-tag')), findsNothing);
    });

    testWidgets('experience booking: "Booked"; without a server-verified flag: no tag', (t) async {
      const booked = ConversationListingContext(
          type: 'experience', id: 'x1', title: 'Cooking class', buyer: true, buyerId: _me);
      await t.pumpWidget(_app(const ListingContextLabel(listingContext: booked, currentUserId: _org)));
      expect(find.text('About: Cooking class'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);
      const plain = ConversationListingContext(type: 'experience', id: 'x1', title: 'Cooking class');
      await t.pumpWidget(_app(const ListingContextLabel(listingContext: plain, currentUserId: _org)));
      expect(find.byKey(const ValueKey('listing-buyer-tag')), findsNothing);
    });

    testWidgets('conversation list row shows the listing label and tag', (t) async {
      final conversation = Conversation(
        conversationId: 'c1',
        matchId: 'search_a_b',
        userId1: _me,
        userId2: _org,
        createdAt: DateTime(2026, 10, 1),
        listingContext: ctx,
      );
      await t.pumpWidget(_app(ConversationCard(
        conversation: conversation,
        otherUserProfile: null,
        currentUserId: _org,
      )));
      await t.pump();
      expect(find.byKey(const ValueKey('listing-context-label')), findsOneWidget);
      expect(find.text('Ticket holder'), findsOneWidget);
    });
  });

  group('context model', () {
    test('parses the stored map; a client write never carries buyer', () {
      final c = ConversationListingContext.fromMap({
        'type': 'event',
        'id': 'ev1',
        'title': ' Samba ',
        'startAt': 1790000000000,
        'buyer': true,
        'buyerId': _me,
      })!;
      expect(c.title, 'Samba');
      expect(c.buyer, isTrue);
      expect(c.showsBuyerTagFor(_org), isTrue);
      expect(c.showsBuyerTagFor(_me), isFalse);
      expect(c.toClientMap().containsKey('buyer'), isFalse);
      expect(c.toClientMap().containsKey('buyerId'), isFalse);
      expect(ConversationListingContext.fromMap({'type': 'group', 'id': 'g'}), isNull);
      expect(ConversationListingContext.fromMap(null), isNull);
      expect(c.copyWith(buyer: false).buyerId, isNull);
    });
  });

  group('deep link ?chat=1', () {
    test('event / experience links with chat=1 open the chat too', () {
      expect(DeepLinkService.parse(Uri.parse('https://greengo-chat.web.app/e/ev1?chat=1')),
          const DeepLinkTarget(DeepLinkKind.event, 'ev1', openChat: true));
      expect(DeepLinkService.parse(Uri.parse('greengo://x/x1?chat=1')),
          const DeepLinkTarget(DeepLinkKind.experience, 'x1', openChat: true));
      final handOff = Uri.parse(
          'https://greengo-chat.web.app/?link=${Uri.encodeComponent('/e/ev1?chat=1')}');
      expect(DeepLinkService.parse(handOff),
          const DeepLinkTarget(DeepLinkKind.event, 'ev1', openChat: true));
    });

    test('plain links and other kinds are unchanged', () {
      expect(DeepLinkService.parse(Uri.parse('https://greengo-chat.web.app/e/ev1')),
          const DeepLinkTarget(DeepLinkKind.event, 'ev1'));
      expect(DeepLinkService.parse(Uri.parse('https://greengo-chat.web.app/u/u1?chat=1')),
          const DeepLinkTarget(DeepLinkKind.profile, 'u1'));
    });
  });
}
