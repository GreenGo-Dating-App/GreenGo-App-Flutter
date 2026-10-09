import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/user_display_name.dart';
import 'package:greengo_chat/features/chat/data/models/conversation_model.dart';
import 'package:greengo_chat/features/chat/domain/chat_system_message.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/presentation/utils/chat_l10n.dart';
import 'package:greengo_chat/features/chat/presentation/utils/support_l10n.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/enhanced_message_bubble.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Client-written chat texts (system lines, coin-gift notes, deleted
/// placeholders, support notices) are stored as `metadata.systemKey` +
/// params with an English `content` fallback, and rendered in the READER's
/// language. Old documents (English `content` only) must still display.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));
  final it = lookupAppLocalizations(const Locale('it'));

  Message msg(
    String content, {
    MessageType type = MessageType.system,
    Map<String, dynamic>? metadata,
  }) =>
      Message(
        messageId: 'm',
        matchId: 'x',
        conversationId: 'c',
        senderId: 'system',
        receiverId: 'u',
        content: content,
        type: type,
        sentAt: DateTime(2026),
        metadata: metadata,
      );

  group('systemKey rendering (new documents)', () {
    test('each key renders in the reader language, not the stored English', () {
      final cases = <Message, String>{
        msg('Start Connecting!',
            metadata: chatSystemMetadata(ChatSystemKey.startConnecting)):
            de.letsExchange,
        msg('ana sent you a Super Like!',
            metadata: chatSystemMetadata(
                ChatSystemKey.superLikeReceived, {'name': 'ana'})):
            de.superLikedYou('ana'),
        msg('ana sent you 50 coins!',
            metadata: chatSystemMetadata(ChatSystemKey.coinsReceived,
                {'name': 'ana', 'amount': 50})):
            de.chatSystemCoinsReceived('ana', 50),
        msg('I just sent you 20 coins!',
            type: MessageType.text,
            metadata:
                chatSystemMetadata(ChatSystemKey.coinsSent, {'amount': 20})):
            de.chatSystemCoinsSent(20),
        msg('This message was deleted',
            type: MessageType.text,
            metadata: chatSystemMetadata(ChatSystemKey.messageDeleted)):
            de.chatMessageDeleted,
        msg('Welcome…',
            metadata: chatSystemMetadata(
                ChatSystemKey.supportWelcome, {'subject': 'Login'})):
            de.chatSystemSupportWelcome('Login'),
        msg('Mia has joined…',
            metadata: chatSystemMetadata(
                ChatSystemKey.supportAgentJoined, {'name': 'Mia'})):
            de.chatSystemSupportAgentJoined('Mia'),
        msg('Ticket status…',
            metadata: chatSystemMetadata(
                ChatSystemKey.supportStatus, {'status': 'resolved'})):
            de.chatSystemSupportResolved,
      };
      cases.forEach((message, expected) {
        expect(chatMessageDisplayText(de, message), expected,
            reason: message.metadata.toString());
        expect(expected, isNot(message.content));
      });
    });

    test('missing names render the localized "Unknown user"', () {
      final m = msg('Someone sent you 5 coins!',
          metadata: chatSystemMetadata(
              ChatSystemKey.coinsReceived, {'name': '', 'amount': 5}));
      expect(chatMessageDisplayText(it, m),
          it.chatSystemCoinsReceived(it.commonUnknownUser, 5));

      final agent = msg('Support Agent has joined…',
          metadata: chatSystemMetadata(
              ChatSystemKey.supportAgentJoined, {'name': ''}));
      expect(chatMessageDisplayText(de, agent),
          de.chatSystemSupportAgentJoined(de.chatSystemSupportAgentFallback));
    });

    test('an unknown key (newer app version) falls back to stored content', () {
      final m = msg('Something new',
          metadata: chatSystemMetadata('someFutureKey', {'x': 1}));
      expect(chatMessageDisplayText(de, m), 'Something new');
    });

    test('every support status has its own line', () {
      for (final s in SupportTicketStatus.values) {
        final text = supportStatusChangeText(de, s.name);
        expect(text, isNotEmpty);
      }
      expect(supportStatusChangeText(de, 'waitingOnUser'),
          de.chatSystemSupportWaitingOnUser);
      expect(supportStatusChangeText(de, 'unknown'),
          de.chatSystemSupportStatusUpdated);
    });
  });

  group('legacy documents (English content only)', () {
    test('known English system lines are localized', () {
      expect(chatMessageDisplayText(de, msg('Start Connecting!')),
          de.letsExchange);
      expect(chatMessageDisplayText(de, msg('Ana sent you a Super Like!')),
          de.superLikedYou('Ana'));
      expect(chatMessageDisplayText(de, msg('Ana sent you 30 coins!')),
          de.chatSystemCoinsReceived('Ana', 30));
      expect(chatMessageDisplayText(de, msg('Someone sent you 30 coins!')),
          de.chatSystemCoinsReceived(de.commonUnknownUser, 30));
      expect(
          chatMessageDisplayText(
              de,
              msg('Welcome to GreenGo Support! A support agent will be with '
                  'you shortly. Your ticket: Login issue')),
          de.chatSystemSupportWelcome('Login issue'));
      expect(
          chatMessageDisplayText(de,
              msg('Support Agent has joined the conversation and will assist you.')),
          de.chatSystemSupportAgentJoined(de.chatSystemSupportAgentFallback));
      expect(chatMessageDisplayText(de, msg('This support ticket has been closed.')),
          de.chatSystemSupportClosed);
      expect(
          chatMessageDisplayText(
              de, msg('This message was deleted', type: MessageType.text)),
          de.chatMessageDeleted);
    });

    test('unknown system text and user text are never rewritten', () {
      expect(chatMessageDisplayText(de, msg('Custom server line')),
          'Custom server line');
      // A user who types a phrase that looks like a system line keeps it.
      expect(
          chatMessageDisplayText(
              de, msg('Start Connecting!', type: MessageType.text)),
          'Start Connecting!');
      expect(
          chatMessageDisplayText(
              de, msg('I just sent you 3 coins!', type: MessageType.text)),
          'I just sent you 3 coins!');
    });

    test('English reader sees the same text as before', () {
      expect(chatMessageDisplayText(en, msg('Start Connecting!')),
          'Start Connecting!');
      expect(chatMessageDisplayText(en, msg('Ana sent you 30 coins!')),
          'Ana sent you 30 coins!');
    });
  });

  group('inbox preview', () {
    Conversation conv(Message last) => Conversation(
          conversationId: 'c',
          matchId: 'x',
          userId1: 'a',
          userId2: 'b',
          createdAt: DateTime(2026),
          lastMessage: last,
        );

    test('system preview is localized from metadata', () {
      final c = conv(msg('Start Connecting!',
          metadata: chatSystemMetadata(ChatSystemKey.startConnecting)));
      expect(chatLastMessagePreview(de, c), de.letsExchange);
    });

    test('media previews never show the stored URL', () {
      final c = conv(msg('https://firebasestorage.googleapis.com/x.jpg',
          type: MessageType.image));
      final preview = chatLastMessagePreview(de, c);
      expect(preview, contains(de.chatPhoto));
      expect(preview, isNot(contains('https://')));
    });

    test('ConversationModel keeps lastMessage.metadata from Firestore', () async {
      final fs = FakeFirebaseFirestore();
      await fs.collection('conversations').doc('c1').set({
        'matchId': 'x',
        'userId1': 'a',
        'userId2': 'b',
        'createdAt': Timestamp.fromDate(DateTime(2026)),
        'lastMessage': {
          'messageId': 'm',
          'senderId': 'system',
          'receiverId': 'b',
          'content': 'Ana sent you a Super Like!',
          'type': 'system',
          'metadata': chatSystemMetadata(
              ChatSystemKey.superLikeReceived, {'name': 'Ana'}),
          'sentAt': Timestamp.fromDate(DateTime(2026)),
        },
      });
      final model = ConversationModel.fromFirestore(
          await fs.collection('conversations').doc('c1').get());
      expect(model.lastMessage?.metadata?['systemKey'],
          ChatSystemKey.superLikeReceived);
      expect(chatLastMessagePreview(it, model), it.superLikedYou('Ana'));
    });
  });

  group('support inbox', () {
    test('app-written subjects are localized, user subjects kept', () {
      expect(
          supportTicketSubject(de, {
            'subject': 'Chat with GreenGo Support',
            'subjectKey': 'support_chat',
          }),
          de.supportChatWithGreenGoSubject);
      expect(
          supportTicketSubject(de, {
            'subject': 'Report Follow-up: spam',
            'subjectKey': 'report_followup',
            'subjectParams': {'reason': 'spam'},
          }),
          de.supportReportFollowUpSubject('spam'));
      expect(supportTicketSubject(de, {'subject': 'Mein Konto'}), 'Mein Konto');
      expect(supportTicketSubject(de, {}), de.adminSupportRequest);
    });

    test('system messages use top-level systemKey, else legacy/stored text', () {
      final followUp = <String, dynamic>{
        'content': 'Report Follow-up\n\nReason: spam',
        'messageType': 'system',
        ...chatSystemMetadata(ChatSystemKey.reportFollowUp, {
          'reason': 'spam',
          'reportedMessage': 'buy now',
          'reportedUser': 'abcd1234...',
          'reportedAt': Timestamp.fromDate(DateTime.utc(2026, 3, 4, 10, 30)),
        }),
      };
      final text = supportMessageDisplayText(de, followUp);
      expect(text, startsWith(de.supportReportFollowUpTitle));
      expect(text, contains('buy now'));
      expect(text, contains('abcd1234...'));
      expect(text, isNot(contains('Reported message')));

      expect(
          supportMessageDisplayText(de, {
            'content': "We're waiting for your response.",
            'messageType': 'system',
          }),
          de.chatSystemSupportWaitingOnUser);
      expect(
          supportMessageDisplayText(
              de, {'content': 'Hallo', 'messageType': 'text'}),
          'Hallo');
    });

    test('ticket card is built from structured fields, legacy text cleaned', () {
      final structured = supportTicketStartText(de, {
        'content': '📋 **New Support Ticket**\n\n**Category:** Billing',
        'ticketCategory': 'billing',
        'ticketSubject': 'Refund',
        'ticketDescription': 'Charged twice',
      });
      expect(structured,
          contains('${de.chatSupportCategory}: ${de.chatCategoryBilling}'));
      expect(structured, contains('${de.chatSupportSubject}: Refund'));
      expect(structured, contains('${de.chatSupportDescription}:'));
      expect(structured, contains('Charged twice'));
      expect(structured, isNot(contains('Category:')));

      final legacy = supportTicketStartText(de, {
        'content': '📋 **New Support Ticket**\n\n**Category:** Billing\n'
            '**Subject:** Refund',
      });
      expect(legacy, 'Category: Billing\nSubject: Refund');
    });
  });

  group('user display name', () {
    test('null, blank and legacy placeholders render the localized label', () {
      for (final v in [null, '', '  ', 'Unknown', 'Someone']) {
        expect(displayUserName(de, v), de.commonUnknownUser, reason: '$v');
        expect(isMissingUserName(v), isTrue);
      }
      expect(displayUserName(de, ' Ana '), 'Ana');
    });
  });

  testWidgets('message bubble renders a stored system line in the viewer '
      'language', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EnhancedMessageBubble(
          message: msg('Ana sent you 50 coins!',
              metadata: chatSystemMetadata(ChatSystemKey.coinsReceived,
                  {'name': 'Ana', 'amount': 50})),
          isCurrentUser: false,
          currentUserId: 'u',
        ),
      ),
    ));
    await tester.pump();
    expect(find.text(de.chatSystemCoinsReceived('Ana', 50)), findsOneWidget);
    expect(find.text('Ana sent you 50 coins!'), findsNothing);
  });
}
