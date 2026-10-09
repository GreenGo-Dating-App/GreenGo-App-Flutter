/// Stable keys for chat messages the APP writes on behalf of the system (or a
/// user) that other people read: "Start Connecting!", super-like / coin-gift
/// notices, support-ticket status lines, "message deleted"...
///
/// The writer stores `metadata.systemKey` (+ `metadata.systemParams`) next to
/// a neutral English `content` fallback. Readers render the text in THEIR
/// language at display time (see `chatMessageDisplayText` in
/// `presentation/utils/chat_l10n.dart`); old app versions and server code
/// (push) keep reading `content`.
abstract final class ChatSystemKey {
  /// Opening line of a new connection conversation. No params.
  static const startConnecting = 'startConnecting';

  /// Priority Connect (super like) received. Params: `name`.
  static const superLikeReceived = 'superLikeReceived';

  /// Coin gift system line shown to both sides. Params: `name`, `amount`.
  static const coinsReceived = 'coinsReceived';

  /// The sender's own "I just sent you N coins!" line. Params: `amount`.
  static const coinsSent = 'coinsSent';

  /// A message deleted for everyone. No params.
  static const messageDeleted = 'messageDeleted';

  /// Support conversation opened. Params: `subject`.
  static const supportWelcome = 'supportWelcome';

  /// A support agent joined. Params: `name` (may be empty).
  static const supportAgentJoined = 'supportAgentJoined';

  /// Support ticket status changed. Params: `status` (SupportTicketStatus.name).
  static const supportStatus = 'supportStatus';

  /// Report follow-up opened by a moderator in the reporter's support chat.
  /// Params: `reason`, `reportedMessage`, `reportedUser`, `reportedAt`
  /// (Timestamp / DateTime).
  static const reportFollowUp = 'reportFollowUp';
}

/// `metadata` map carrying [key] and its [params] for a stored chat message.
Map<String, dynamic> chatSystemMetadata(
  String key, [
  Map<String, dynamic> params = const <String, dynamic>{},
]) =>
    <String, dynamic>{
      'systemKey': key,
      if (params.isNotEmpty) 'systemParams': params,
    };
