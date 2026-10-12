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
