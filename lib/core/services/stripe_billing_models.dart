/// Plain data returned by the `getStripeBillingSummary` Cloud Function (web
/// only). Platform-neutral so the mobile stub can return empty lists without
/// linking any Stripe code.
class WebSubscriptionInfo {
  const WebSubscriptionInfo({
    required this.name,
    required this.amountCents,
    required this.currency,
    required this.interval,
    required this.status,
    required this.cancelAtPeriodEnd,
    this.currentPeriodEnd,
  });

  final String name;
  final int? amountCents;
  final String? currency;

  /// 'month' | 'year' (Stripe recurring interval).
  final String? interval;
  final String status;
  final bool cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd;

  factory WebSubscriptionInfo.fromMap(Map<String, dynamic> m) =>
      WebSubscriptionInfo(
        name: (m['name'] ?? '').toString(),
        amountCents: (m['amountCents'] as num?)?.toInt(),
        currency: m['currency'] as String?,
        interval: m['interval'] as String?,
        status: (m['status'] ?? '').toString(),
        cancelAtPeriodEnd: m['cancelAtPeriodEnd'] == true,
        currentPeriodEnd: DateTime.tryParse((m['currentPeriodEnd'] ?? '').toString()),
      );
}

class WebOrderInfo {
  const WebOrderInfo({
    required this.orderId,
    required this.name,
    required this.withdrawable,
    this.type,
    this.amountCents,
    this.currency,
    this.createdAt,
    this.withdrawalDeadline,
  });

  final String orderId;
  final String name;
  final String? type;
  final int? amountCents;
  final String? currency;
  final DateTime? createdAt;
  final bool withdrawable;
  final DateTime? withdrawalDeadline;

  factory WebOrderInfo.fromMap(Map<String, dynamic> m) => WebOrderInfo(
        orderId: (m['orderId'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        type: m['type'] as String?,
        amountCents: (m['amountCents'] as num?)?.toInt(),
        currency: m['currency'] as String?,
        createdAt: DateTime.tryParse((m['createdAt'] ?? '').toString()),
        withdrawable: m['withdrawable'] == true,
        withdrawalDeadline:
            DateTime.tryParse((m['withdrawalDeadline'] ?? '').toString()),
      );
}

class WebBillingSummary {
  const WebBillingSummary({
    this.subscriptions = const [],
    this.orders = const [],
  });

  final List<WebSubscriptionInfo> subscriptions;
  final List<WebOrderInfo> orders;

  static const empty = WebBillingSummary();

  factory WebBillingSummary.fromMap(Map<String, dynamic> m) {
    List<Map<String, dynamic>> list(Object? v) => (v is List ? v : const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return WebBillingSummary(
      subscriptions:
          list(m['subscriptions']).map(WebSubscriptionInfo.fromMap).toList(),
      orders: list(m['orders']).map(WebOrderInfo.fromMap).toList(),
    );
  }
}
