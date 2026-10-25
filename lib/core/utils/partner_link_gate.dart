import '../services/own_profile_store.dart';
import 'base_membership_gate.dart';

/// Partner booking links (Ticketmaster live events, Viator experiences) follow
/// the participation rule ([BaseMembershipGate.canParticipate]): since
/// 2026-10-25 every known account sees their "Open link", the free version
/// included (was a membership perk from 2026-10-12). Curated / Wikipedia /
/// Google attractions are not affected.
class PartnerLinkGate {
  const PartnerLinkGate._();

  static const Set<String> partnerSources = {'ticketmaster', 'viator'};

  /// `ExternalEvent.source` of a partner item.
  static bool isPartnerSource(String source) =>
      partnerSources.contains(source.toLowerCase());

  /// A shared chat card only carries the URL and a display label
  /// (`ExternalEvent.sourceLabel`), so match either.
  static bool isPartnerShare({String? url, String? sourceLabel}) {
    if (isPartnerSource(sourceLabel ?? '')) return true;
    final host = Uri.tryParse(url ?? '')?.host.toLowerCase() ?? '';
    return host.contains('viator.') || host.contains('ticketmaster.');
  }

  /// Whether [userId] may see / open partner links. Fails CLOSED while the
  /// own profile is unknown (the shell's live listener fills it at sign-in).
  static bool canOpen(String userId) =>
      BaseMembershipGate.canParticipate(OwnProfileStore.instance.peek(userId));

  /// The link of an item with [source] is shown to [userId].
  static bool showLink({required String source, required String userId}) =>
      !isPartnerSource(source) || canOpen(userId);
}
