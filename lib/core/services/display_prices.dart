import '../constants/launch_promo.dart';

/// Parses the `getDisplayPrices` callable response
/// `{prices: {productId: {display, currency, amountCents}}}` into
/// canonical productId -> display label (e.g. `'0,99 €'` for IT).
///
/// Malformed or empty entries are skipped, so a partial answer still yields
/// every price it can; anything missing keeps its caller-side fallback.
Map<String, String> parseDisplayPrices(Object? data) {
  final map = <String, String>{};
  final prices = data is Map ? data['prices'] : null;
  if (prices is! Map) return map;
  prices.forEach((key, value) {
    final display = value is Map ? value['display'] : null;
    if (key is String && display is String && display.trim().isNotEmpty) {
      map[key] = display;
    }
  });
  return map;
}

/// Parses the optional `promo` objects of a `getDisplayPrices` (or, keyed by
/// its own productId, `getMembershipPrice`) response into launch prices:
/// `prices[productId].promo = {display, amountCents, interval, endsAt, ...}`.
/// Only while [LaunchPromo.isActive] and the server's `endsAt` is still ahead.
/// An answer without `promo` (older server) yields an empty map.
Map<String, PromoPrice> parseDisplayPromos(Object? data, {DateTime? now}) {
  final out = <String, PromoPrice>{};
  final at = (now ?? LaunchPromo.now()).toUtc();
  if (!LaunchPromo.isActive(at)) return out;
  final prices = data is Map ? data['prices'] : null;
  if (prices is! Map) return out;
  prices.forEach((key, value) {
    if (key is! String || value is! Map) return;
    final promo = value['promo'];
    if (promo is! Map) return;
    final display = promo['display'];
    if (display is! String || display.trim().isEmpty) return;
    final ends = promo['endsAt'] is String ? DateTime.tryParse(promo['endsAt'] as String) : null;
    if (ends != null && !at.isBefore(ends.toUtc())) return;
    final cents = promo['amountCents'];
    final regularCents = value['amountCents'];
    final regular = value['display'];
    out[key] = PromoPrice(
      yearly: promo['interval'] == 'year',
      launchLabel: display,
      launchAmount: cents is num ? cents / 100 : null,
      regularLabel: regular is String && regular.trim().isNotEmpty ? regular : null,
      regularAmount: regularCents is num ? regularCents / 100 : null,
    );
  });
  return out;
}
