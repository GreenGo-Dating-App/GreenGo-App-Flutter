import '../../membership/domain/entities/membership.dart';
import '../../profile/domain/entities/profile.dart';

/// The ONE set of "may this person be shown to this viewer" rules for every
/// people surface (Discovery grid, Explore people rows) — used by the server
/// paths AND by every cached (LastResultCache) paint, so a cached preview can
/// never show someone the fresh load would hide.
///
/// Swipe history (recent passes) and boosts are ordering/feed concerns handled
/// by the discovery stack, not visibility; they are not part of this.
class DiscoveryVisibility {
  DiscoveryVisibility._();

  /// Explicitly removed accounts (the matching scan's rule).
  static bool isRemovedAccount(Profile p) {
    final status = p.accountStatus.toLowerCase();
    return p.isBanned ||
        status == 'suspended' ||
        status == 'banned' ||
        status == 'deleted';
  }

  /// Ghost mode (always hidden) or an unexpired incognito window.
  static bool isPrivacyHidden(Profile p, [DateTime? now]) {
    if (p.isGhostMode) return true;
    final expiry = p.incognitoExpiry;
    return p.isIncognito && expiry != null && expiry.isAfter(now ?? DateTime.now());
  }

  /// A profile with an empty / placeholder display name (e.g. registration
  /// never finished) is not discoverable by other users.
  static bool hasNoUsableName(Profile p) {
    final name = p.displayName.trim().toLowerCase();
    return name.isEmpty || name == 'unknown' || name == 'unknown user';
  }

  /// A profile with neither a real country nor real coordinates (onboarding
  /// never finished) is not discoverable by other users.
  static bool hasNoUsableLocation(Profile p) {
    final loc = p.effectiveLocation;
    final country = loc.country.trim().toLowerCase();
    final noCountry = country.isEmpty || country == 'unknown';
    final noCoords = loc.latitude == 0 && loc.longitude == 0;
    return noCountry || noCoords;
  }

  /// Whether [p] may be shown to [viewerId].
  ///
  ///  * [blockedIds]: the viewer's bidirectional block list.
  ///  * [viewerIsPrivileged]: admin/support viewers also see testers and
  ///    incomplete profiles.
  ///  * [allowSupport]: the Discovery grid shows the (reachable) support
  ///    account; admin accounts are always hidden.
  static bool isVisible(
    Profile p, {
    required String viewerId,
    Set<String> blockedIds = const <String>{},
    bool viewerIsPrivileged = false,
    bool allowSupport = false,
    DateTime? now,
  }) {
    if (p.userId == viewerId) return false;
    if (blockedIds.contains(p.userId)) return false;
    if (p.isAdmin) return false;
    if (p.isSupport && !allowSupport) return false;
    if (isRemovedAccount(p)) return false;
    if (isPrivacyHidden(p, now)) return false;
    // Admin/support candidates are exempt from the completeness/tester rules.
    if (p.isSupport) return true;
    if (!viewerIsPrivileged) {
      if (p.membershipTier == MembershipTier.test) return false;
      if (hasNoUsableName(p) || hasNoUsableLocation(p)) return false;
    }
    return true;
  }
}
