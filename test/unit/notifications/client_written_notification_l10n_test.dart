import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/coins/domain/entities/invoice.dart';
import 'package:greengo_chat/features/coins/presentation/coin_l10n.dart';
import 'package:greengo_chat/features/notifications/domain/entities/notification.dart';
import 'package:greengo_chat/features/notifications/presentation/utils/notification_text_l10n.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Notifications the APP writes for another user (photo like, coin gift,
/// Priority Connect, business approval, chat) carry a stable kind/type +
/// params and are rendered in the RECEIVER's language; documents written
/// before that keep displaying (via the English phrase table or as stored).
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));
  final fr = lookupAppLocalizations(const Locale('fr'));

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

  test('photo like: rendered from data.kind + liker fields', () {
    final like = n(NotificationType.system, 'New Photo Like',
        '@ana liked your photo', {
      'kind': 'photo_like',
      'likerName': 'Ana',
      'likerNickname': 'ana',
    });
    expect(localizedNotificationTitle(de, like), de.notifNewPhotoLikeTitle);
    expect(localizedNotificationBody(de, like), de.notifLikedYourPhoto('@ana'));

    final anonymous = n(NotificationType.system, 'New Photo Like',
        'Someone liked your photo', {'kind': 'photo_like', 'likerName': ''});
    expect(localizedNotificationBody(fr, anonymous),
        fr.notifLikedYourPhoto(fr.commonUnknownUser));
  });

  test('coin gift: title + body from data, legacy body via pattern', () {
    final gift = n(NotificationType.system, 'You received coins!',
        'ana sent you 40 coins!', {
      'kind': 'coin_gift',
      'senderName': 'ana',
      'amount': 40,
    });
    expect(localizedNotificationTitle(de, gift), de.notifCoinsReceivedTitle);
    expect(localizedNotificationBody(de, gift),
        de.chatSystemCoinsReceived('ana', 40));

    final legacy = n(NotificationType.system, 'You received coins!',
        'Someone sent you 40 coins!', {'senderId': 's'});
    expect(localizedNotificationTitle(de, legacy), de.notifCoinsReceivedTitle);
    expect(localizedNotificationBody(de, legacy),
        de.chatSystemCoinsReceived(de.commonUnknownUser, 40));
  });

  test('business verified: owner sees it in their language even when the '
      'admin wrote it in another one', () {
    // Legacy doc written in the admin's (German) language, no data.kind.
    final legacy = n(NotificationType.system,
        de.adminBusinessVerifiedNotificationTitle,
        de.adminBusinessVerifiedNotificationBody, {'businessVerified': true});
    expect(localizedNotificationTitle(fr, legacy),
        fr.adminBusinessVerifiedNotificationTitle);
    expect(localizedNotificationBody(fr, legacy),
        fr.adminBusinessVerifiedNotificationBody);

    final current = n(NotificationType.system,
        en.adminBusinessVerifiedNotificationTitle,
        en.adminBusinessVerifiedNotificationBody,
        {'businessVerified': true, 'kind': 'business_verified'});
    expect(localizedNotificationTitle(de, current),
        de.adminBusinessVerifiedNotificationTitle);
  });

  test('Priority Connect (client-written super like) is rebuilt from data', () {
    final sl = n(NotificationType.superLike, en.youGotSuperLike,
        en.superLikedYou('Ana'),
        {'senderUserId': 's', 'senderDisplayName': 'Ana'});
    expect(localizedNotificationTitle(de, sl), de.youGotSuperLike);
    expect(localizedNotificationBody(de, sl), de.superLikedYou('Ana'));

    final noName = n(NotificationType.superLike, en.youGotSuperLike, '...',
        {'senderUserId': 's', 'senderDisplayName': ''});
    expect(localizedNotificationBody(de, noName),
        de.superLikedYou(de.commonUnknownUser));
  });

  test('chat notifications with no sender name use "Unknown user"', () {
    final chat = n(NotificationType.newChat, 'New Conversation',
        'Someone started a conversation with you.',
        {'senderNickname': '', 'senderName': ''});
    expect(localizedNotificationBody(de, chat),
        de.notifStartedConversation(de.commonUnknownUser));

    final legacy = n(NotificationType.newMessage, 'New message from Someone',
        'hi', {'senderNickname': '', 'senderName': 'Someone'});
    expect(localizedNotificationTitle(de, legacy),
        de.notifNewMessageFrom(de.commonUnknownUser));
    expect(localizedNotificationBody(de, legacy), 'hi');
  });

  test('a notification with no known kind keeps its stored text', () {
    final other = n(NotificationType.system, 'Custom title', 'Custom body',
        {'kind': 'something_new'});
    expect(localizedNotificationTitle(de, other), 'Custom title');
    expect(localizedNotificationBody(de, other), 'Custom body');
  });

  group('invoice lines', () {
    InvoiceLineItem line(String description, {String? kind, int? coins}) =>
        InvoiceLineItem(
          itemId: 'p',
          description: description,
          quantity: 1,
          unitPrice: 1,
          totalPrice: 1,
          kind: kind,
          coinCount: coins,
        );

    test('rendered from kind, legacy description kept', () {
      expect(
          localizedInvoiceLineItem(
              de, line('500 GreenGo Coins', kind: InvoiceLineKind.coins, coins: 500)),
          de.invoiceLineCoins(500));
      expect(
          localizedInvoiceLineItem(de,
              line('Subscription Plan', kind: InvoiceLineKind.subscription)),
          de.invoiceLineSubscription);
      expect(
          localizedInvoiceLineItem(
              de, line('Coin Gift Package', kind: InvoiceLineKind.gift)),
          de.invoiceLineGiftPackage);
      expect(localizedInvoiceLineItem(de, line('500 GreenGo Coins')),
          '500 GreenGo Coins');
    });
  });
}
