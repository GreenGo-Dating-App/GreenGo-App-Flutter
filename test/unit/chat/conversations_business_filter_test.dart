import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';

import '../../support/chat_fixtures.dart';

/// Master Test Plan — Chat/Messaging. Business-tab filtering regression.
///
/// Pure replica of `_passesFilter` in conversations_screen.dart for the
/// `ConversationFilter.all` case. The regression it guards: a BUSINESS viewer's
/// incoming business-inquiry conversations must be EXCLUDED from the personal
/// Messages filters (they belong in the dedicated "Business" tab); a customer
/// (non-business viewer) keeps their copy in Messages.
enum _Filter { all, newMessages, notReplied, favorites, toApprove }

bool _passesFilter(
  Conversation conversation, {
  required String viewerId,
  required bool viewerIsBusiness,
  _Filter filter = _Filter.all,
}) {
  // Business inquiries live in the Business tab for a business viewer.
  if (viewerIsBusiness && conversation.businessInquiry) {
    return false;
  }
  final deletedForMe = conversation.isDeleted ||
      (conversation.deletedFor?.containsKey(viewerId) ?? false);
  final isRealChat = conversation.lastMessage != null && !deletedForMe;
  if (filter != _Filter.toApprove && !isRealChat) {
    return false;
  }
  switch (filter) {
    case _Filter.all:
      return conversation.conversationType != ConversationType.support &&
          conversation.conversationType != ConversationType.search &&
          !(conversation.isSuperLikeConversation &&
              conversation.visibleTo != null);
    case _Filter.newMessages:
    case _Filter.notReplied:
      if (conversation.isSuperLikeConversation &&
          conversation.visibleTo != null) {
        return false;
      }
      return conversation.unreadCount > 0 &&
          conversation.lastMessage != null &&
          !conversation.lastMessage!.isSentBy(viewerId);
    case _Filter.favorites:
      return conversation.isFavoritedBy(viewerId);
    case _Filter.toApprove:
      return conversation.isSuperLikeConversation &&
          conversation.visibleTo != null &&
          conversation.visibleTo!.contains(viewerId);
  }
}

void main() {
  group('_passesFilter — business inquiry exclusion', () {
    test('business viewer: business inquiry is EXCLUDED from All', () {
      final inquiry = ChatFixtures.conversation(
        businessInquiry: true,
        lastMessage: ChatFixtures.message(),
      );

      expect(
        _passesFilter(inquiry, viewerId: 'elena', viewerIsBusiness: true),
        isFalse,
      );
    });

    test('customer viewer: same inquiry STAYS in All (no Business tab)', () {
      final inquiry = ChatFixtures.conversation(
        businessInquiry: true,
        lastMessage: ChatFixtures.message(),
      );

      expect(
        _passesFilter(inquiry, viewerId: 'ava', viewerIsBusiness: false),
        isTrue,
      );
    });

    test('business viewer: non-inquiry chat still passes', () {
      final normal = ChatFixtures.conversation(
        lastMessage: ChatFixtures.message(),
      );

      expect(
        _passesFilter(normal, viewerId: 'elena', viewerIsBusiness: true),
        isTrue,
      );
    });

    test('business exclusion applies to newMessages filter too', () {
      final inquiry = ChatFixtures.conversation(
        businessInquiry: true,
        unreadCount: 4,
        lastMessage: ChatFixtures.message(senderId: 'ava'),
      );

      expect(
        _passesFilter(inquiry,
            viewerId: 'elena',
            viewerIsBusiness: true,
            filter: _Filter.newMessages),
        isFalse,
      );
    });
  });

  group('_passesFilter — general chat rules', () {
    test('conversation with no lastMessage is not a real chat', () {
      final empty = ChatFixtures.conversation();
      expect(
        _passesFilter(empty, viewerId: 'ava', viewerIsBusiness: false),
        isFalse,
      );
    });

    test('All excludes support and search conversations', () {
      final support = ChatFixtures.conversation(
        conversationType: ConversationType.support,
        lastMessage: ChatFixtures.message(),
      );
      final search = ChatFixtures.conversation(
        conversationType: ConversationType.search,
        lastMessage: ChatFixtures.message(),
      );

      expect(
        _passesFilter(support, viewerId: 'ava', viewerIsBusiness: false),
        isFalse,
      );
      expect(
        _passesFilter(search, viewerId: 'ava', viewerIsBusiness: false),
        isFalse,
      );
    });

    test('All excludes a pending super-like (visibleTo set)', () {
      final pending = ChatFixtures.conversation(
        conversationType: ConversationType.superLike,
        visibleTo: const ['ava'],
        superLikeSenderId: 'elena',
        lastMessage: ChatFixtures.message(),
      );

      expect(
        _passesFilter(pending, viewerId: 'ava', viewerIsBusiness: false),
        isFalse,
      );
    });

    test('deletedFor the viewer removes it from All', () {
      final deleted = ChatFixtures.conversation(
        lastMessage: ChatFixtures.message(),
        deletedFor: const {'ava': true},
      );

      expect(
        _passesFilter(deleted, viewerId: 'ava', viewerIsBusiness: false),
        isFalse,
      );
      // still visible to the other participant
      expect(
        _passesFilter(deleted, viewerId: 'elena', viewerIsBusiness: false),
        isTrue,
      );
    });

    test('favorites filter matches only favorited conversations', () {
      final fav = ChatFixtures.conversation(
        lastMessage: ChatFixtures.message(),
        favorites: const {'ava': true},
      );

      expect(
        _passesFilter(fav,
            viewerId: 'ava',
            viewerIsBusiness: false,
            filter: _Filter.favorites),
        isTrue,
      );
      expect(
        _passesFilter(fav,
            viewerId: 'elena',
            viewerIsBusiness: false,
            filter: _Filter.favorites),
        isFalse,
      );
    });
  });
}
