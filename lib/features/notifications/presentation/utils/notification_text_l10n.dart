import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/utils/chat_l10n.dart';
import '../../domain/entities/notification.dart';

/// Display-time localization of in-app notification text.
///
/// Notification docs are written by Cloud Functions with ENGLISH `title` /
/// `message` strings (see functions/src/notifications/*, social/follows.ts,
/// ticket_payments/orders.ts…). Until the server stores a code + params, the
/// client recognises the known server phrases and renders them in the
/// viewer's language; anything unknown falls back to the stored text.
///
/// The English patterns below must mirror the server strings exactly.
String localizeStoredNotificationText(AppLocalizations l10n, String text) {
  final t = text.trim();
  if (t.isEmpty) return text;

  final exact = _exact(l10n)[t];
  if (exact != null) return exact;

  for (final p in _patterns(l10n)) {
    final m = p.re.firstMatch(t);
    if (m != null) return p.build(m.group(1)!.trim());
  }
  return text;
}

/// Sender label stored by the client-written chat notifications.
String _sender(NotificationEntity n) {
  final d = n.data ?? const <String, dynamic>{};
  final nick = (d['senderNickname'] as String?)?.trim() ?? '';
  final name = (d['senderName'] as String?)?.trim() ?? '';
  return nick.isNotEmpty ? '@$nick' : name;
}

/// Localized title of [n]: known client-written types (chat) are rebuilt from
/// `type` + `data`; everything else goes through the server-phrase table.
String localizedNotificationTitle(AppLocalizations l10n, NotificationEntity n) {
  final who = _sender(n);
  switch (n.type) {
    case NotificationType.newChat:
      if (n.title.trim() == 'New Conversation') {
        return l10n.notifNewConversationTitle;
      }
      break;
    case NotificationType.newMessage:
      if (who.isNotEmpty && n.title.startsWith('New message from ')) {
        return l10n.notifNewMessageFrom(who);
      }
      break;
    default:
      break;
  }
  return localizeStoredNotificationText(l10n, n.title);
}

/// Localized body of [n] (see [localizedNotificationTitle]).
String localizedNotificationBody(AppLocalizations l10n, NotificationEntity n) {
  final who = _sender(n);
  switch (n.type) {
    case NotificationType.newChat:
      if (who.isNotEmpty) return l10n.notifStartedConversation(who);
      break;
    case NotificationType.newMessage:
      final raw = n.data?['messageType'] as String?;
      if (raw != null) {
        final type = MessageType.values.where((t) => t.name == raw);
        if (type.isNotEmpty) {
          final label = chatMessageTypeLabel(l10n, type.first);
          if (label != null) return label;
        }
      }
      break;
    default:
      break;
  }
  return localizeStoredNotificationText(l10n, n.message);
}

/// Localized relative time for a notification's `createdAt`.
String notificationTimeAgo(
    AppLocalizations l10n, String locale, DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return l10n.chatJustNow;
  if (diff.inMinutes < 60) return l10n.chatSupportMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.chatSupportHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.chatSupportDaysAgo(diff.inDays);
  return DateFormat.yMd(locale).format(createdAt);
}

// The English map keys below are server-written text to match, not UI.
Map<String, String> _exact(AppLocalizations l10n) => {
      // Social / engagement (actor name is rendered separately, before the phrase)
      'viewed your profile': l10n.notifServerViewedYourProfile,
      'started following you': l10n.notifServerStartedFollowingYou,
      'started following your business': l10n.notifServerStartedFollowingBusiness,
      'rated your business': l10n.notifServerRatedYourBusiness,
      'reviewed your experience': l10n.notifServerReviewedYourExperience,
      'Tap to see who stopped by': l10n.notifServerTapToSeeWhoStoppedBy,
      'Tap to see their profile': l10n.notifServerTapToSeeTheirProfile,
      'You have a new follower': l10n.notifServerNewFollower,
      'You have a new rating': l10n.notifServerNewRating,
      'Your community': l10n.notifServerYourCommunity,
      'Your event': l10n.notifServerYourEvent,
      // Boosts
      'Your profile boost is now live': l10n.notifServerProfileBoostLive,
      'Your profile boost has ended': l10n.notifServerProfileBoostEnded,
      'Your profile is being promoted to more people': l10n.notifServerProfilePromoted,
      'Your event is being promoted in Explore': l10n.notifServerEventPromoted,
      'Boost again to keep reaching more people': l10n.notifServerBoostAgainProfile,
      'Boost again to keep it featured': l10n.notifServerBoostAgainEvent,
      // Tickets
      "You're checked in — enjoy!": l10n.notifServerCheckedIn,
      'Your ticket is ready': l10n.notifServerTicketReady,
      'Ticket sold': l10n.notifServerTicketSold,
      'Payment to confirm': l10n.notifServerPaymentToConfirm,
      'Payment not confirmed': l10n.notifServerPaymentNotConfirmed,
      'Payments waiting for your confirmation': l10n.notifServerPaymentsWaiting,
      'Ticket refunded': l10n.notifServerTicketRefunded,
      'Ticket payment disputed': l10n.notifServerTicketDisputed,
      'Refund to pay back': l10n.notifServerRefundToPayBack,
      'Ticket reservation expired': l10n.notifServerTicketReservationExpired,
      // Experiences / safety
      'Your experience was hidden after several reports': l10n.notifServerExperienceHidden,
      'Pending review by GreenGo': l10n.notifServerPendingReview,
      // Coins / support / modes / verification
      'Monthly coins added': l10n.notifServerMonthlyCoinsAdded,
      'Support replied to your ticket': l10n.notifServerSupportReplied,
      'You have a new reply from support.': l10n.notifServerSupportNewReply,
      'Incognito Mode Expiring Soon': l10n.notifServerIncognitoExpiring,
      'Your Incognito Mode expires in less than 1 hour!': l10n.notifServerIncognitoExpiringBody,
      'Traveler Mode Expiring Soon': l10n.notifServerTravelerExpiring,
      'Your Traveler Mode expires in less than 1 hour!': l10n.notifServerTravelerExpiringBody,
      'Profile Verified!': l10n.notifServerProfileVerified,
      'Your profile has been verified! You now have a verified badge.': l10n.notifServerProfileVerifiedBody,
      'New Verification Photo Needed': l10n.notifServerNewVerificationPhoto,
      'Verification Update': l10n.notifServerVerificationUpdate,
      // Client-written docs (other users' devices)
      'New Photo Like': l10n.notifNewPhotoLikeTitle,
      'You received coins!': l10n.notifCoinsReceivedTitle,
    };

class _Pattern {
  const _Pattern(this.re, this.build);
  final RegExp re;
  final String Function(String arg) build;
}

List<_Pattern> _patterns(AppLocalizations l10n) => [
      _Pattern(RegExp(r'^rated your business (\d+)★$'),
          (a) => l10n.notifServerRatedYourBusinessStars(int.tryParse(a) ?? 0)),
      _Pattern(RegExp(r'^joined your community (.+)$'),
          l10n.notifServerJoinedYourCommunity),
      _Pattern(RegExp(r'^joined your event (.+)$'),
          l10n.notifServerJoinedYourEvent),
      _Pattern(RegExp(r'^liked your event (.+)$'),
          l10n.notifServerLikedYourEvent),
      _Pattern(RegExp(r'^joined your group (.+)$'),
          l10n.notifServerJoinedYourGroup),
      _Pattern(RegExp(r'^added you as a co-owner of (.+)$'),
          l10n.notifServerAddedYouAsCoOwner),
      _Pattern(RegExp(r'^added you to (.+)$'), l10n.notifServerAddedYouToGroup),
      _Pattern(RegExp(r'^Your event (.+) boost is now live$'),
          l10n.notifServerEventBoostLive),
      _Pattern(RegExp(r'^Your event (.+) boost has ended$'),
          l10n.notifServerEventBoostEnded),
      _Pattern(RegExp(r'^Your ticket for (.+) was scanned$'),
          l10n.notifServerTicketScanned),
      _Pattern(RegExp(r'^New event in (.+)$'), l10n.notifServerNewEventIn),
      _Pattern(RegExp(r'^Event cancelled in (.+)$'),
          l10n.notifServerEventCancelledIn),
      _Pattern(RegExp(r'^Event updated in (.+)$'),
          l10n.notifServerEventUpdatedIn),
      _Pattern(RegExp(r'^New event from (.+)$'), l10n.notifServerNewEventFrom),
      _Pattern(RegExp(r'^(.+) liked your photo$'), l10n.notifLikedYourPhoto),
      _Pattern(RegExp(r'^Announcement · (.+)$'),
          l10n.notifServerAnnouncement),
    ];
