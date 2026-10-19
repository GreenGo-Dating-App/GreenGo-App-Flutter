import '../../profile/domain/entities/profile.dart';

/// ONE source of truth for the business PROFILE name (`profiles/{uid}
/// .businessName`, the storefront display name), edited in both the Business
/// account screen and the storefront editor.
///
/// Rules (unchanged from the Business account screen): trimmed, required
/// (non-empty) for business accounts. There is no server/rules constraint on
/// the field (no uniqueness, no length cap), so none is added client side.
class BusinessName {
  const BusinessName._();

  static String normalize(String raw) => raw.trim();

  static bool isValid(String raw) => normalize(raw).isNotEmpty;

  /// The name a business is shown under: its business name, falling back to
  /// the personal display name only when none was set (legacy).
  static String displayFor(Profile p) {
    final n = p.businessName?.trim() ?? '';
    return n.isNotEmpty ? n : p.displayName;
  }
}
