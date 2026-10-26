/// Who can see a business account's store (Business Center > Storefront >
/// Store visibility). Owner-written `profiles/{uid}.storeVisibility`; a
/// missing or unknown value is [visible].
enum StoreVisibility {
  /// Default: the store is in Discover, Explore and search.
  visible('visible'),

  /// Not in Discover, Explore or search. Followers, chats and direct links
  /// still open the storefront.
  hiddenFromDiscovery('hidden'),

  /// Nobody but the owner sees the store: to everyone else the account looks
  /// like a personal profile (no storefront, business name, logo or store pin).
  fullyHidden('off');

  const StoreVisibility(this.wire);

  /// Firestore value (also read by functions/src/profiles/storeVisibility.ts).
  final String wire;

  static StoreVisibility fromWire(Object? v) {
    for (final s in values) {
      if (s.wire == v) return s;
    }
    return visible;
  }
}
