import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/notifications/domain/entities/notification.dart';
import 'package:greengo_chat/features/notifications/presentation/utils/notification_text_l10n.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));

  NotificationEntity n(NotificationType type, String title, String message,
          [Map<String, dynamic>? data]) =>
      NotificationEntity(
        notificationId: 'n',
        userId: 'u',
        type: type,
        title: title,
        message: message,
        data: data,
        createdAt: DateTime(2026),
      );

  test('known server phrases are localized, English round-trips', () {
    expect(localizeStoredNotificationText(de, 'viewed your profile'),
        de.notifServerViewedYourProfile);
    expect(localizeStoredNotificationText(en, 'joined your event Jazz Night'),
        'joined your event Jazz Night');
    expect(localizeStoredNotificationText(de, 'joined your event Jazz Night'),
        de.notifServerJoinedYourEvent('Jazz Night'));
    expect(localizeStoredNotificationText(de, 'rated your business 4★'),
        de.notifServerRatedYourBusinessStars(4));
  });

  test('unknown text falls back to the stored text', () {
    expect(localizeStoredNotificationText(de, 'Something custom'),
        'Something custom');
  });

  test('chat notifications are rebuilt from type + data', () {
    final msg = n(NotificationType.newMessage, 'New message from @ana', '📷',
        {'senderNickname': 'ana', 'messageType': 'image'});
    expect(localizedNotificationTitle(de, msg), de.notifNewMessageFrom('@ana'));
    expect(localizedNotificationBody(en, msg), contains(en.chatPhoto));

    final chat = n(NotificationType.newChat, 'New Conversation',
        '@ana started a conversation with you.', {'senderNickname': 'ana'});
    expect(localizedNotificationTitle(de, chat), de.notifNewConversationTitle);
    expect(localizedNotificationBody(en, chat),
        '@ana started a conversation with you.');
  });
}
