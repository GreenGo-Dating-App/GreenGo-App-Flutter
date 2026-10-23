import 'package:cloud_functions/cloud_functions.dart';

/// Why a Buddy callable was refused, read from `details.reason` /
/// `details.code` (functions/src/buddies/buddies.ts).
enum BuddyErrorKind {
  /// `insufficient-coins`: the free replies are used up and no coin is left.
  insufficientCoins,

  /// `AI_CONSENT_REQUIRED`: no accepted AI notice on the server.
  consentRequired,

  /// `AI_CONSENT_UPDATE_REQUIRED`: the provider needs a newer AI notice.
  consentUpdateRequired,

  /// `tier-required`: Buddy limit reached / this Buddy is locked on the plan.
  tierRequired,

  /// `RATE_LIMITED`: too many messages in 10 minutes.
  rateLimited,

  /// `AI_UNAVAILABLE`: no model answered (the charge was refunded).
  unavailable,

  /// `TEXT_TOO_LONG`: more than 500 characters.
  textTooLong,

  /// `DUPLICATE_REQUEST`: the same requestId is still being answered.
  duplicate,

  /// Anything else (network, invalid argument, not found ...).
  other,
}

/// A refused Buddy call. [cause] is the original error (for the generic
/// user-error popup and logs).
class BuddyException implements Exception {
  const BuddyException(this.kind, {this.cause, this.limit, this.max});

  final BuddyErrorKind kind;
  final Object? cause;

  /// The plan's Buddy limit (`tier-required` on create), when given.
  final int? limit;

  /// The max message length (`TEXT_TOO_LONG`), when given.
  final int? max;

  /// Maps any thrown object; FirebaseFunctionsException details are read the
  /// way the server writes them: `refusal()` puts `{reason, ...extra}` in
  /// details, `AppError` puts `{code, details: {reason?, ...}}`.
  static BuddyException from(Object error) {
    if (error is BuddyException) return error;
    if (error is! FirebaseFunctionsException) {
      return BuddyException(BuddyErrorKind.other, cause: error);
    }
    final d = error.details;
    final top = d is Map ? d : const <Object?, Object?>{};
    final inner = top['details'] is Map ? top['details'] as Map : const <Object?, Object?>{};
    final reason = (top['reason'] ?? inner['reason'] ?? top['code'])?.toString();
    final message = error.message ?? '';
    int? asInt(Object? v) => v is num ? v.toInt() : null;
    final limit = asInt(top['limit']) ?? asInt(inner['limit']);
    final max = asInt(inner['max']) ?? asInt(top['max']);

    BuddyErrorKind kind;
    switch (reason) {
      case 'insufficient-coins':
        kind = BuddyErrorKind.insufficientCoins;
        break;
      case 'AI_CONSENT_REQUIRED':
        kind = BuddyErrorKind.consentRequired;
        break;
      case 'AI_CONSENT_UPDATE_REQUIRED':
        kind = BuddyErrorKind.consentUpdateRequired;
        break;
      case 'tier-required':
        kind = BuddyErrorKind.tierRequired;
        break;
      case 'RATE_LIMITED':
        kind = BuddyErrorKind.rateLimited;
        break;
      case 'AI_UNAVAILABLE':
        kind = BuddyErrorKind.unavailable;
        break;
      case 'TEXT_TOO_LONG':
        kind = BuddyErrorKind.textTooLong;
        break;
      case 'DUPLICATE_REQUEST':
        kind = BuddyErrorKind.duplicate;
        break;
      default:
        // Refusals carry the reason as a message prefix too.
        if (message.startsWith('insufficient-coins')) {
          kind = BuddyErrorKind.insufficientCoins;
        } else if (message.startsWith('tier-required')) {
          kind = BuddyErrorKind.tierRequired;
        } else {
          kind = BuddyErrorKind.other;
        }
    }
    return BuddyException(kind, cause: error, limit: limit, max: max);
  }

  @override
  String toString() => 'BuddyException(${kind.name}): $cause';
}
