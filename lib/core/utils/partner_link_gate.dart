import '../services/own_profile_store.dart';
import 'base_membership_gate.dart';

/// Partner booking links (Ticketmaster live events, Viator experiences) are a
/// membership perk (owner rule 2026-10-12): a FREE user never sees their
/// "Open link". Base membership or any active paid tier (same predicate as
/// participation, [BaseMembershipGate.canParticipate]) unlocks them.
/// Curated / Wikipedia / Google attractions are not affected.
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
