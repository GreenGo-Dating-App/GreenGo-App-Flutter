import '../../../../generated/app_localizations.dart';
import 'chat_l10n.dart';

// Display-time localization for the support inbox (`support_chats` /
// `support_messages`). Writers store stable keys next to an English fallback
// (read by the admin panel and older app versions); the app renders the keys
// in the viewer's language and falls back to the stored text otherwise.

/// Localized label of a support ticket category code.
String supportCategoryLabel(AppLocalizations l10n, String? code) {
  switch (code) {
    case 'general':
      return l10n.chatCategoryGeneral;
    case 'technical':
      return l10n.chatCategoryTechnical;
    case 'billing':
      return l10n.chatCategoryBilling;
    case 'account':
      return l10n.chatCategoryAccount;
    case 'safety':
      return l10n.chatCategorySafety;
    case 'feedback':
      return l10n.chatCategoryFeedback;
    case 'report_followup':
      return l10n.supportReportFollowUpTitle;
    default:
      return code ?? '';
  }
}

/// Subject of a `support_chats` ticket: app-written subjects (`subjectKey`)
/// are localized, user-typed subjects are shown as written.
String supportTicketSubject(AppLocalizations l10n, Map<String, dynamic> ticket) {
  final rawParams = ticket['subjectParams'];
  final params = rawParams is Map
      ? Map<String, dynamic>.from(rawParams)
      : const <String, dynamic>{};
  switch (ticket['subjectKey']) {
    case 'support_chat':
      return l10n.supportChatWithGreenGoSubject;
    case 'report_followup':
      return l10n.supportReportFollowUpSubject(
          params['reason'] as String? ?? '');
  }
  final subject = ticket['subject'];
  if (subject is String && subject.isNotEmpty) return subject;
  return l10n.adminSupportRequest;
}

/// Text of a `support_messages` system line (`systemKey` / `systemParams` at
/// the top level of the doc), or the stored `content` for anything else.
String supportMessageDisplayText(
    AppLocalizations l10n, Map<String, dynamic> message) {
  final content = message['content'] as String? ?? '';
  final key = message['systemKey'];
  if (key is String) {
    final rawParams = message['systemParams'];
    final params = rawParams is Map
        ? Map<String, dynamic>.from(rawParams)
        : const <String, dynamic>{};
    final text = chatSystemText(l10n, key, params);
    if (text != null) return text;
  }
  if (message['messageType'] == 'system' || message['senderType'] == 'system') {
    return localizeLegacyChatSystemText(l10n, content) ?? content;
  }
  return content;
}

/// Body of the ticket-creation card. Uses the structured fields when present
/// (localized labels and category); older tickets show the stored text with
/// its markdown header removed.
String supportTicketStartText(
    AppLocalizations l10n, Map<String, dynamic> message) {
  final subject = message['ticketSubject'];
  if (subject is String) {
    final lines = <String>[
      '${l10n.chatSupportCategory}: '
          '${supportCategoryLabel(l10n, message['ticketCategory'] as String?)}',
      '${l10n.chatSupportSubject}: $subject',
    ];
    final description = (message['ticketDescription'] as String?)?.trim() ?? '';
    if (description.isNotEmpty) {
      lines
        ..add('')
        ..add('${l10n.chatSupportDescription}:')
        ..add(description);
    }
    return lines.join('\n');
  }
  final content = message['content'] as String? ?? '';
  return content
      .replaceAll('📋 **New Support Ticket**\n\n', '')
      .replaceAll('**', '');
}
