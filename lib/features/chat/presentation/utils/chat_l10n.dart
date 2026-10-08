import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
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
  return chatMessageTypeLabel(l10n, last.type) ?? last.content;
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
