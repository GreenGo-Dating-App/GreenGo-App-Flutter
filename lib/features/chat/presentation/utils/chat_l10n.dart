import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/server_text.dart';
import '../../../../core/utils/user_display_name.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/chat_system_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

// Display-time localization for chat entities. The domain layer keeps
// stable types/timestamps (and English fallbacks); the UI maps them to the
// viewer's language here.

/// Localized label for a non-text message type (used in previews).
String? chatMessageTypeLabel(AppLocalizations l10n, MessageType type) {
  switch (type) {
    case MessageType.image:
      return '📷 ${l10n.chatPhoto}';
    case MessageType.video:
      return '🎥 ${l10n.chatVideo}';
    case MessageType.gif:
      return 'GIF'; // i18n-ignore: format name
    case MessageType.sticker:
      return '✨ ${l10n.chatPreviewSticker}';
    case MessageType.voiceNote:
      return '🎤 ${l10n.chatPreviewVoiceMessage}';
    case MessageType.albumShare:
      return '📷 ${l10n.chatPreviewAlbumShared}';
    case MessageType.albumRevoke:
      return '🔒 ${l10n.chatPreviewAlbumRevoked}';
    case MessageType.location:
      return '📍 ${l10n.chatLocation}';
    case MessageType.event:
      return '📅 ${l10n.chatPreviewEvent}';
    case MessageType.text:
    case MessageType.system:
      return null;
  }
}

/// Localized last-message preview for a conversation list row.
String chatLastMessagePreview(AppLocalizations l10n, Conversation conversation) {
  final last = conversation.lastMessage;
  if (last == null) return l10n.chatPreviewSayHi;
  return chatMessageTypeLabel(l10n, last.type) ??
      chatMessageDisplayText(l10n, last);
}

/// Text to show for [message] in the VIEWER's language.
///
/// Messages written by the app (system lines, coin-gift notes, deleted
/// placeholders) carry `metadata.systemKey` + `metadata.systemParams` and are
/// rendered from those. Documents written by older app versions only have the
/// English `content`: known system phrases are recognised and localized;
/// anything else (including all user-typed text) is returned unchanged.
String chatMessageDisplayText(AppLocalizations l10n, Message message) {
  final meta = message.metadata;
  final key = meta?['systemKey'];
  if (key is String) {
    final raw = meta?['systemParams'];
    final params =
        raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    final text = chatSystemText(l10n, key, params);
    if (text != null) return text;
  }
  final content = message.content;
  // Only app-written lines are matched: user text is never rewritten (the
  // "deleted" placeholder replaced the user's content, so it is safe too).
  if (message.type == MessageType.system || content == _legacyDeleted) {
    return localizeLegacyChatSystemText(l10n, content) ?? content;
  }
  return content;
}

/// Localized text for a stored [ChatSystemKey] (null when [key] is unknown,
/// e.g. written by a newer app version — the caller falls back to `content`).
String? chatSystemText(
  AppLocalizations l10n,
  String key,
  Map<String, dynamic> params,
) {
  String name() => displayUserName(l10n, params['name'] as String?);
  int amount() => (params['amount'] as num?)?.toInt() ?? 0;
  switch (key) {
    case ChatSystemKey.startConnecting:
      return l10n.letsExchange;
    case ChatSystemKey.superLikeReceived:
      return l10n.superLikedYou(name());
    case ChatSystemKey.coinsReceived:
      return l10n.chatSystemCoinsReceived(name(), amount());
    case ChatSystemKey.coinsSent:
      return l10n.chatSystemCoinsSent(amount());
    case ChatSystemKey.messageDeleted:
      return l10n.chatMessageDeleted;
    case ChatSystemKey.supportWelcome:
      return l10n.chatSystemSupportWelcome(params['subject'] as String? ?? '');
    case ChatSystemKey.supportAgentJoined:
      final agent = (params['name'] as String?)?.trim() ?? '';
      return l10n.chatSystemSupportAgentJoined(
          agent.isEmpty ? l10n.chatSystemSupportAgentFallback : agent);
    case ChatSystemKey.supportStatus:
      return supportStatusChangeText(l10n, params['status'] as String?);
    case ChatSystemKey.reportFollowUp:
      final details = l10n.supportReportFollowUpDetails(
        params['reason'] as String? ?? '',
        params['reportedMessage'] as String? ?? '',
        params['reportedUser'] as String? ?? '',
        _formatStoredDate(params['reportedAt'], l10n.localeName),
      );
      return '${l10n.supportReportFollowUpTitle}\n\n$details';
    case ChatSystemKey.screenshotTaken:
      return l10n.chatSystemScreenshotTaken(name());
  }
  // Keys written by the SERVER (members joined/left, message removed by a
  // moderator, AI support hand-off, ...) - null when unknown to this version.
  return serverText(l10n, key, params);
}

/// Localized "ticket status changed" line for a SupportTicketStatus name.
String supportStatusChangeText(AppLocalizations l10n, String? status) {
  switch (status) {
    case 'inProgress':
      return l10n.chatSystemSupportInProgress;
    case 'waitingOnUser':
      return l10n.chatSystemSupportWaitingOnUser;
    case 'resolved':
      return l10n.chatSystemSupportResolved;
    case 'closed':
      return l10n.chatSystemSupportClosed;
    default:
      return l10n.chatSystemSupportStatusUpdated;
  }
}

String _formatStoredDate(Object? raw, String? locale) {
  final DateTime? at = raw is Timestamp
      ? raw.toDate()
      : raw is DateTime
          ? raw
          : raw is String
              ? DateTime.tryParse(raw)
              : null;
  if (at == null) return '';
  try {
    return DateFormat.yMd(locale).add_Hm().format(at.toLocal());
  } catch (_) {
    return DateFormat.yMd().add_Hm().format(at.toLocal());
  }
}

// English text stored by older app versions. These are DATA to match, not UI.
const _legacyDeleted = 'This message was deleted';
const _legacyStartConnecting = 'Start Connecting!';
final _legacySuperLike = RegExp(r'^(.+) sent you a Super Like!$');
final _legacyCoinsReceived = RegExp(r'^(.+) sent you (\d+) coins!$');
final _legacySupportWelcome = RegExp(
    r'^Welcome to GreenGo Support! A support agent will be with you shortly\. Your ticket: (.*)$',
    dotAll: true);
final _legacyAgentJoined =
    RegExp(r'^(.+) has joined the conversation and will assist you\.$');
const _legacySupportStatus = <String, String>{
  'Support agent is working on your issue.': 'inProgress',
  "We're waiting for your response.": 'waitingOnUser',
  'Your issue has been resolved. Thank you for contacting GreenGo Support!':
      'resolved',
  'This support ticket has been closed.': 'closed',
  'Ticket status updated.': 'updated',
};

/// Localized form of an English system line stored by an older app version,
/// or null when [content] is not one of them.
String? localizeLegacyChatSystemText(AppLocalizations l10n, String content) {
  final t = content.trim();
  if (t == _legacyDeleted) return l10n.chatMessageDeleted;
  if (t == _legacyStartConnecting) return l10n.letsExchange;
  final status = _legacySupportStatus[t];
  if (status != null) return supportStatusChangeText(l10n, status);
  var m = _legacyCoinsReceived.firstMatch(t);
  if (m != null) {
    return l10n.chatSystemCoinsReceived(
        displayUserName(l10n, m.group(1)), int.tryParse(m.group(2)!) ?? 0);
  }
  m = _legacySuperLike.firstMatch(t);
  if (m != null) return l10n.superLikedYou(displayUserName(l10n, m.group(1)));
  m = _legacySupportWelcome.firstMatch(t);
  if (m != null) return l10n.chatSystemSupportWelcome(m.group(1)!);
  m = _legacyAgentJoined.firstMatch(t);
  if (m != null) {
    final agent = m.group(1)!;
    return l10n.chatSystemSupportAgentJoined(
        agent == 'Support Agent' ? l10n.chatSystemSupportAgentFallback : agent);
  }
  return null;
}

/// Compact "time since" label for a conversation list row ("5m", "2h").
String chatShortTimeSince(BuildContext context, AppLocalizations l10n, DateTime? at) {
  if (at == null) return '';
  final difference = DateTime.now().difference(at);
  if (difference.inMinutes < 1) return l10n.chatJustNow;
  if (difference.inMinutes < 60) return l10n.chatTimeShortMinutes(difference.inMinutes);
  if (difference.inHours < 24) return l10n.chatTimeShortHours(difference.inHours);
  if (difference.inDays < 7) return l10n.chatTimeShortDays(difference.inDays);
  return MaterialLocalizations.of(context).formatCompactDate(at);
}

/// Message clock time in the viewer's locale format (e.g. "10:30 AM" / "10:30").
String chatClockTime(BuildContext context, DateTime at) {
  final localizations = MaterialLocalizations.of(context);
  return localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(at),
    alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
}
