import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';
import 'package:greengo_chat/features/chat/domain/entities/group_info.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/conversation_card.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../support/profile_fixtures.dart';

Message buildMessage({
  String senderId = 'other',
  String content = 'Hello there',
  MessageType type = MessageType.text,
}) {
  return Message(
    messageId: 'm1',
    matchId: 'match1',
    conversationId: 'conv1',
    senderId: senderId,
    receiverId: 'me',
    content: content,
    type: type,
    sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
  );
}

Conversation buildConversation({
  Message? lastMessage,
  int unreadCount = 0,
  bool businessInquiry = false,
  bool isTyping = false,
  String? typingUserId,
  bool isGroup = false,
  GroupInfo? groupInfo,
}) {
  return Conversation(
    conversationId: 'conv1',
    matchId: 'match1',
    userId1: 'me',
    userId2: 'other',
    createdAt: DateTime(2026, 1, 1),
    lastMessage: lastMessage,
    lastMessageAt: lastMessage?.sentAt,
    unreadCount: unreadCount,
    businessInquiry: businessInquiry,
    isTyping: isTyping,
    typingUserId: typingUserId,
    isGroup: isGroup,
    groupInfo: groupInfo,
  );
}

Future<void> pumpCard(WidgetTester tester, ConversationCard card) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: card),
    ),
  );
}

void main() {
  testWidgets('shows the other user displayName for a normal 1:1 chat',
      (tester) async {
    final other = buildProfile(displayName: 'Bruno Costa', photoUrls: const []);
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(lastMessage: buildMessage()),
          otherUserProfile: other,
          currentUserId: 'me',
        ),
      ),
    );

    expect(find.text('Bruno Costa'), findsOneWidget);
    expect(find.text('Hello there'), findsOneWidget);
  });

  testWidgets(
      'business inquiry shows the businessName instead of the owner name',
      (tester) async {
    // Network-free storefront profile (no cover / no photos) so the tile only
    // renders the identity icon — the assertion is purely about the NAME.
    final Profile business = buildProfile(
      userId: 'biz',
      displayName: 'Elena Marco',
      isBusiness: true,
      businessName: "Elena's Cafe",
      photoUrls: const [],
    );
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(businessInquiry: true),
          otherUserProfile: business,
          currentUserId: 'me',
        ),
      ),
    );

    expect(find.text("Elena's Cafe"), findsOneWidget);
    // The owner's personal name must NOT be shown for a business inquiry.
    expect(find.text('Elena Marco'), findsNothing);
  });

  testWidgets('business inquiry avatar uses the storefront coverImageUrl',
      (tester) async {
    final business = buildBusinessProfile(
      coverImageUrl: 'https://example.com/elena_cover.jpg',
    );
    await mockNetworkImagesFor(() async {
      await pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(businessInquiry: true),
          otherUserProfile: business,
          currentUserId: 'me',
        ),
      );

      // Reading the widget property is synchronous and does not require the
      // image to finish loading.
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      final provider = avatar.backgroundImage;
      expect(provider, isA<CachedNetworkImageProvider>());
      expect(
        (provider! as CachedNetworkImageProvider).url,
        'https://example.com/elena_cover.jpg',
      );

      // Flush + swallow the deferred cache-manager load error (path_provider is
      // not mocked in the widget-test host).
      await tester.pump();
      tester.takeException();
    });
  });

  testWidgets('a NON-business profile keeps the personal displayName',
      (tester) async {
    // businessInquiry flag set but the profile is not a business -> personal.
    final other = buildProfile(displayName: 'Bruno Costa', photoUrls: const []);
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(businessInquiry: true),
          otherUserProfile: other,
          currentUserId: 'me',
        ),
      ),
    );
    expect(find.text('Bruno Costa'), findsOneWidget);
  });

  testWidgets('group conversation shows the group name', (tester) async {
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(
            isGroup: true,
            groupInfo: const GroupInfo(name: 'Culture Circle', createdBy: 'me'),
          ),
          otherUserProfile: null,
          currentUserId: 'me',
        ),
      ),
    );
    expect(find.text('Culture Circle'), findsOneWidget);
  });

  testWidgets('shows a typing indicator when the other user is typing',
      (tester) async {
    final other = buildProfile(photoUrls: const []);
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(
            isTyping: true,
            typingUserId: 'other',
          ),
          otherUserProfile: other,
          currentUserId: 'me',
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders the unread count badge', (tester) async {
    final other = buildProfile(photoUrls: const []);
    await mockNetworkImagesFor(() async {
      await pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(
            lastMessage: buildMessage(senderId: 'other'),
            unreadCount: 5,
          ),
          otherUserProfile: other,
          currentUserId: 'me',
        ),
      );
      expect(find.text('5'), findsOneWidget);

      // Unread schedules a delayed shimmer; advance past it + the animation so
      // no timer/ticker is left pending at teardown.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 1300));
    });
  });

  testWidgets('falls back to a person icon when there is no avatar',
      (tester) async {
    final other = buildProfile(photoUrls: const []);
    await mockNetworkImagesFor(
      () => pumpCard(
        tester,
        ConversationCard(
          conversation: buildConversation(),
          otherUserProfile: other,
          currentUserId: 'me',
        ),
      ),
    );
    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
