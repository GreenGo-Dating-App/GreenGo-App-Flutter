/// Per-SESSION gate for the cache-then-network reads.
///
/// The Firestore offline cache is persistent (survives app close), so reading
/// from it on a FRESH app open would paint the previous session's — possibly
/// stale or partial — data before the network reconciles. That read as "data
/// not displaying / wrong data" on launch.
///
/// This gate tracks, per app SESSION (the set is static, so it resets to empty
/// on every process restart / fresh launch), which data domains have already
/// been loaded from the SERVER this session. Cache-then-network callers should:
///   1. Only do the fast `Source.cache` paint when [isWarm] is true (i.e. we
///      already have a validated server copy THIS session).
///   2. Call [markWarm] after a successful SERVER load.
/// Net effect: a fresh app open goes NETWORK-FIRST; subsequent loads in the same
/// session paint instantly from the cache, then reconcile.
class SessionCacheGate {
  SessionCacheGate._();

  static final Set<String> _warmed = <String>{};

  /// GLOBAL KILL-SWITCH. While true, the cache-first paint is DISABLED
  /// everywhere and every read goes to the network (serverAndCache = fresh when
  /// online). Turned on because the cache-first passes were surfacing stale /
  /// partial / no data and adding round-trips (slower). Flip to false to
  /// re-enable cache-then-network once the loading is verified correct.
  static const bool disabled = true;

  // Well-known keys (one per cache-then-network data domain).
  static const communitiesDiscover = 'communities_discover';
  static const communitiesJoined = 'communities_joined';
  static const communitiesMy = 'communities_my';
  static const eventsAll = 'events_all';
  static const eventsUser = 'events_user';
  static const exploreCommunityEvents = 'explore_community_events';
  static const exploreCommunities = 'explore_communities';

  /// True once [key] has been loaded from the SERVER during this app session.
  /// Always false while [disabled] — forces every read to the network.
  static bool isWarm(String key) => !disabled && _warmed.contains(key);

  /// Mark [key] as freshly loaded from the server this session.
  static void markWarm(String key) => _warmed.add(key);

  /// Reset (e.g. on sign-out) so the next user/session goes network-first again.
  static void reset() => _warmed.clear();
}
