import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/domain/entities/group_info.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/conversation_card.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../support/business_fixtures.dart';
import '../../support/chat_fixtures.dart';

/// Master Test Plan — Chat/Messaging. ConversationCard business-identity
/// regression: for a business INQUIRY where the other party is a business with a
/// non-empty businessName, the tile shows the STOREFRONT identity (businessName)
/// instead of the owner's personal displayName. Otherwise it shows displayName.
Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('business inquiry shows businessName, not personal displayName',
      (tester) async {
    await mockNetworkImagesFor(() async {
      final biz = BusinessFixtures.business(
        userId: 'elena',
        displayName: 'Elena Marco',
        businessName: "Elena's Cafe",
      );
      final conv = ChatFixtures.conversation(
        userId1: 'ava',
        userId2: 'elena',
        businessInquiry: true,
        lastMessage: ChatFixtures.message(senderId: 'ava'),
      );

      await tester.pumpWidget(_host(
        ConversationCard(
          conversation: conv,
          otherUserProfile: biz,
          currentUserId: 'ava',
        ),
      ));
      await tester.pump();

      expect(find.text("Elena's Cafe"), findsOneWidget);
      expect(find.text('Elena Marco'), findsNothing);
    });
  });

  testWidgets('non-business inquiry shows the personal displayName',
      (tester) async {
    await mockNetworkImagesFor(() async {
      final person = BusinessFixtures.person(
        userId: 'elena',
        displayName: 'Elena Marco',
      );
      final conv = ChatFixtures.conversation(
        userId1: 'ava',
        userId2: 'elena',
        lastMessage: ChatFixtures.message(senderId: 'ava'),
      );

      await tester.pumpWidget(_host(
        ConversationCard(
          conversation: conv,
          otherUserProfile: person,
          currentUserId: 'ava',
        ),
      ));
      await tester.pump();

      expect(find.text('Elena Marco'), findsOneWidget);
    });
  });

  testWidgets('business inquiry WITHOUT businessName falls back to displayName',
      (tester) async {
    await mockNetworkImagesFor(() async {
      // isBusiness but empty businessName → not the storefront identity path.
      final biz = BusinessFixtures.business(
        userId: 'elena',
        displayName: 'Elena Marco',
        businessName: '',
      );
      final conv = ChatFixtures.conversation(
        userId1: 'ava',
        userId2: 'elena',
        businessInquiry: true,
        lastMessage: ChatFixtures.message(senderId: 'ava'),
      );

      await tester.pumpWidget(_host(
        ConversationCard(
          conversation: conv,
          otherUserProfile: biz,
          currentUserId: 'ava',
        ),
      ));
      await tester.pump();

      expect(find.text('Elena Marco'), findsOneWidget);
    });
  });

  testWidgets('group conversation shows the group name', (tester) async {
    await mockNetworkImagesFor(() async {
      final group = ChatFixtures.groupConversation(
        groupInfo: const GroupInfo(name: 'Lisbon Explorers', createdBy: 'ava'),
        lastMessage: ChatFixtures.message(senderId: 'ava'),
      );

      await tester.pumpWidget(_host(
        ConversationCard(
          conversation: group,
          otherUserProfile: null,
          currentUserId: 'ava',
        ),
      ));
      await tester.pump();

      expect(find.text('Lisbon Explorers'), findsOneWidget);
    });
  });
}
