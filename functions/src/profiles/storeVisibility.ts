/**
 * Store visibility (owner choice, Business Center > Storefront; app twin
 * lib/features/profile/domain/entities/store_visibility.dart).
 * `profiles/{uid}.storeVisibility`:
 *   'visible' (or missing)  store everywhere (default)
 *   'hidden'                not in Discover / Explore / search: no
 *                           businessGeohash, so geo queries never read it
 *   'off'                   fully hidden: everyone but the owner sees the
 *                           personal profile (no store pin, preview or
 *                           "new event from a store you follow" push)
 */
export type StoreVisibility = 'visible' | 'hidden' | 'off';

export const STORE_VISIBILITY_FIELD = 'storeVisibility';

export function storeVisibilityOf(pub: any): StoreVisibility {
  const v = pub?.[STORE_VISIBILITY_FIELD];
  return v === 'hidden' || v === 'off' ? v : 'visible';
}

/** The store is left out of discovery (hidden or fully hidden). */
export function storeHiddenFromDiscovery(pub: any): boolean {
  return storeVisibilityOf(pub) !== 'visible';
}

/** Others must see this account as a personal profile. */
export function storeFullyHidden(pub: any): boolean {
  return storeVisibilityOf(pub) === 'off';
}
