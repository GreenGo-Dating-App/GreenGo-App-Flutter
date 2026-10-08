import 'package:equatable/equatable.dart';

/// External payment providers a user can list on their profile so other users
/// can pay them DIRECTLY. GreenGo never processes, holds or takes a cut of
/// these payments — the app only opens the provider's own link, which the OS
/// hands to the provider's app when installed (universal/app links) or to the
/// browser otherwise. Allowed under App Store 3.2.1(vi) / 3.1.3(d)(e) and the
/// Play Payments policy peer-to-peer exemption: never use these for anything
/// unlocked inside GreenGo (coins, membership, features) — that stays IAP.
enum PaymentMethod {
  pix('pix', 'Pix', []),
  mercadoPago('mercadoPago', 'Mercado Pago', []),
  picPay('picPay', 'PicPay', ['picpay.me', 'www.picpay.me']),
  paypal('paypal', 'PayPal', ['paypal.me', 'www.paypal.me', 'paypal.com', 'www.paypal.com']),
  venmo('venmo', 'Venmo', ['venmo.com', 'www.venmo.com', 'account.venmo.com']),
  cashApp('cashApp', 'Cash App', ['cash.app', 'www.cash.app']),
  revolut('revolut', 'Revolut', ['revolut.me', 'www.revolut.me']),
  wise('wise', 'Wise', ['wise.com', 'www.wise.com']),
  monzo('monzo', 'Monzo', ['monzo.me', 'www.monzo.me']),
  kofi('kofi', 'Ko-fi', ['ko-fi.com', 'www.ko-fi.com']),
  stripe('stripe', 'Stripe', []);

  const PaymentMethod(this.key, this.label, this.hosts);

  /// Firestore map key.
  final String key;

  /// Brand name (not translated).
  final String label;

  /// Hosts a pasted URL may come from. Empty = custom check (Pix, Mercado
  /// Pago, Stripe).
  final List<String> hosts;

  static PaymentMethod? fromKey(String key) {
    for (final m in values) {
      if (m.key == key) return m;
    }
    return null;
  }

  /// Pix has no web link: the payer copies the key / "Pix Copia e Cola" code
  /// into their own bank app. Every other method opens [url].
  bool get opensLink => this != PaymentMethod.pix;

  /// Turns what the user typed (a handle like `@name` / `$name`, or a full
  /// link from this provider) into the value we store, or null if invalid.
  /// Handles are stored bare; Mercado Pago and Stripe store the full https
  /// link because their payment links have no handle form; Pix stores the key.
  String? normalize(String input) {
    final v = input.trim();
    if (v.isEmpty) return null;
    // Pix phones/CPFs are often typed with spaces; checked in its own parser.
    if (this == PaymentMethod.pix) return _normalizePixKey(v);
    if (RegExp(r'\s').hasMatch(v)) return null;

    final looksLikeUrl =
        v.contains('/') || v.startsWith('http') || v.startsWith('www.');

    if (this == PaymentMethod.mercadoPago || this == PaymentMethod.stripe) {
      if (!looksLikeUrl) return null;
      final uri = _parse(v);
      if (uri == null) return null;
      final ok = this == PaymentMethod.mercadoPago
          ? _isMercadoPagoHost(uri.host)
          : uri.host.toLowerCase() == 'buy.stripe.com';
      if (!ok || uri.pathSegments.every((s) => s.isEmpty)) return null;
      return uri.replace(scheme: 'https').toString();
    }

    if (!looksLikeUrl) {
      final handle = v.replaceAll(RegExp(r'^[@$]+'), '');
      return _validHandle(handle) ? handle : null;
    }

    final uri = _parse(v);
    if (uri == null || !hosts.contains(uri.host.toLowerCase())) return null;
    // The handle is the last non-empty path segment for every provider:
    // paypal.me/name, venmo.com/u/name, cash.app/$name, revolut.me/name,
    // wise.com/pay/me/name, monzo.me/name, picpay.me/name, ko-fi.com/name.
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final handle = segments.last.replaceAll(RegExp(r'^[@$]+'), '');
    return _validHandle(handle) ? handle : null;
  }

  /// The link opened when someone taps "pay". [value] is a stored value
  /// (already normalized). For Pix this is just the key (nothing to open).
  String url(String value) {
    switch (this) {
      case PaymentMethod.pix:
        return value;
      case PaymentMethod.picPay:
        return 'https://picpay.me/$value';
      case PaymentMethod.monzo:
        return 'https://monzo.me/$value';
      case PaymentMethod.kofi:
        return 'https://ko-fi.com/$value';
      case PaymentMethod.stripe:
        return value;
      case PaymentMethod.paypal:
        return 'https://paypal.me/$value';
      case PaymentMethod.venmo:
        return 'https://venmo.com/u/$value';
      case PaymentMethod.cashApp:
        return 'https://cash.app/\$$value';
      case PaymentMethod.revolut:
        return 'https://revolut.me/$value';
      case PaymentMethod.wise:
        return 'https://wise.com/pay/me/$value';
      case PaymentMethod.mercadoPago:
        return value;
    }
  }

  static Uri? _parse(String v) {
    final uri = Uri.tryParse(v.startsWith('http') ? v : 'https://$v');
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  /// Pix keys (DICT): e-mail, phone in +55 E.164, CPF (11 digits), CNPJ (14
  /// digits) or random key (UUID). Phones MUST carry the + prefix so an
  /// 11-digit mobile is never confused with a CPF.
  static String? _normalizePixKey(String v) {
    if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return v.length <= 77 ? v.toLowerCase() : null;
    }
    if (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(v)) {
      return v.toLowerCase();
    }
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (v.startsWith('+')) {
      return RegExp(r'^55[1-9][0-9]{9,10}$').hasMatch(digits)
          ? '+$digits'
          : null;
    }
    if (!RegExp(r'^[0-9.\-/ ]+$').hasMatch(v)) return null;
    if (digits.length == 11 && _validCpf(digits)) return digits;
    if (digits.length == 14 && _validCnpj(digits)) return digits;
    return null;
  }

  static bool _validCpf(String d) {
    if (RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
    int check(int len) {
      var sum = 0;
      for (var i = 0; i < len; i++) {
        sum += int.parse(d[i]) * (len + 1 - i);
      }
      final r = (sum * 10) % 11;
      return r == 10 ? 0 : r;
    }
    return check(9) == int.parse(d[9]) && check(10) == int.parse(d[10]);
  }

  static bool _validCnpj(String d) {
    if (RegExp(r'^(\d)\1{13}$').hasMatch(d)) return false;
    int check(List<int> weights) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += int.parse(d[i]) * weights[i];
      }
      final r = sum % 11;
      return r < 2 ? 0 : 11 - r;
    }
    const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    return check(w1) == int.parse(d[12]) && check(w2) == int.parse(d[13]);
  }

  static bool _validHandle(String h) =>
      RegExp(r'^[A-Za-z0-9._-]{2,40}$').hasMatch(h);

  // mpago.la / mpago.li short links and mercadopago.com[.xx] (incl. subdomains
  // like link.mercadopago.com.br) across all Latin-American TLDs.
  static bool _isMercadoPagoHost(String host) {
    final h = host.toLowerCase();
    return h == 'mpago.la' ||
        h == 'mpago.li' ||
        RegExp(r'^([a-z0-9-]+\.)*mercadopago\.com(\.[a-z]{2})?$').hasMatch(h);
  }
}

/// Payment Links Entity
/// The user's own external payment handles, keyed by provider.
class PaymentLinks extends Equatable {
  const PaymentLinks([this.values = const {}]);

  /// Stored (normalized) value per provider; absent = not set.
  final Map<PaymentMethod, String> values;

  bool get hasAnyLink => values.values.any((v) => v.isNotEmpty);

  /// Providers that are set, in enum (display) order.
  List<PaymentMethod> get methods => PaymentMethod.values
      .where((m) => (values[m] ?? '').isNotEmpty)
      .toList();

  String? valueOf(PaymentMethod m) {
    final v = values[m];
    return (v == null || v.isEmpty) ? null : v;
  }

  String? urlOf(PaymentMethod m) {
    final v = valueOf(m);
    return v == null ? null : m.url(v);
  }

  @override
  List<Object?> get props => [
        for (final m in PaymentMethod.values) values[m],
      ];
}
