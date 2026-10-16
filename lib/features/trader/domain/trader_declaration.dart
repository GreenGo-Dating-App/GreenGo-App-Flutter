import 'package:equatable/equatable.dart';

import '../../finance_documents/domain/billing_profile.dart';

/// Trader declaration of a host / seller (Terms 12.4, EU Digital Services Act
/// art. 30). functions/src/legal/traderDeclaration.ts is authoritative: it
/// validates every field and keeps the full record server-only; the owner sees
/// the ID number only masked. Address fields reuse the invoice-details model.
class TraderDeclaration extends Equatable {
  const TraderDeclaration({
    required this.isTrader,
    this.name = '',
    this.address,
    this.phone = '',
    this.email = '',
    this.idNumberMasked = '',
    this.idNumberSource,
    this.tradeRegister = '',
    this.tradeRegisterNumber = '',
    this.selfCertified = false,
  });

  static TraderDeclaration? fromMap(Object? raw) {
    if (raw is! Map) return null;
    String s(String k) => (raw[k] as String?)?.trim() ?? '';
    final a = raw['address'];
    return TraderDeclaration(
      isTrader: raw['isTrader'] == true,
      name: s('name'),
      address: a is Map ? BillingAddress.fromMap(a) : null,
      phone: s('phone'),
      email: s('email'),
      idNumberMasked: s('idNumberMasked'),
      idNumberSource: raw['idNumberSource'] as String?,
      tradeRegister: s('tradeRegister'),
      tradeRegisterNumber: s('tradeRegisterNumber'),
      selfCertified: raw['selfCertified'] == true,
    );
  }

  final bool isTrader;
  final String name;
  final BillingAddress? address;
  final String phone;
  final String email;
  final String idNumberMasked;
  final String? idNumberSource;
  final String tradeRegister;
  final String tradeRegisterNumber;
  final bool selfCertified;

  @override
  List<Object?> get props => [
        isTrader, name, address, phone, email, idNumberMasked, idNumberSource,
        tradeRegister, tradeRegisterNumber, selfCertified,
      ];
}

/// getMyTraderDeclaration: the saved declaration (null = never declared) and
/// what the invoice details can fill in.
class TraderStatus extends Equatable {
  const TraderStatus({this.declaration, this.billing});

  factory TraderStatus.fromMap(Map<dynamic, dynamic> m) {
    final b = m['billing'];
    return TraderStatus(
      declaration: TraderDeclaration.fromMap(m['declaration']),
      billing: b is Map ? TraderBillingPrefill.fromMap(b) : null,
    );
  }

  final TraderDeclaration? declaration;
  final TraderBillingPrefill? billing;

  bool get declared => declaration != null;

  @override
  List<Object?> get props => [declaration, billing];
}

/// The invoice details (finance_billing_profiles) a trader can reuse.
class TraderBillingPrefill extends Equatable {
  const TraderBillingPrefill({
    this.legalName = '',
    this.address,
    this.email = '',
    this.phone = '',
    this.hasTaxId = false,
    this.taxIdMasked = '',
  });

  factory TraderBillingPrefill.fromMap(Map<dynamic, dynamic> m) {
    String s(String k) => (m[k] as String?)?.trim() ?? '';
    final a = m['address'];
    return TraderBillingPrefill(
      legalName: s('legalName'),
      address: a is Map ? BillingAddress.fromMap(a) : null,
      email: s('email'),
      phone: s('phone'),
      hasTaxId: m['hasTaxId'] == true,
      taxIdMasked: s('taxIdMasked'),
    );
  }

  final String legalName;
  final BillingAddress? address;
  final String email;
  final String phone;
  final bool hasTaxId;
  final String taxIdMasked;

  @override
  List<Object?> get props => [legalName, address, email, phone, hasTaxId, taxIdMasked];
}

/// What the client sends to saveMyTraderDeclaration.
class TraderDraft {
  const TraderDraft({
    required this.isTrader,
    this.name = '',
    this.address = const BillingAddress(),
    this.phone = '',
    this.email = '',
    this.idNumber = '',
    this.tradeRegister = '',
    this.tradeRegisterNumber = '',
    this.selfCertified = false,
    this.useBillingProfile = false,
  });

  final bool isTrader;
  final String name;
  final BillingAddress address;
  final String phone;
  final String email;
  final String idNumber;
  final String tradeRegister;
  final String tradeRegisterNumber;
  final bool selfCertified;
  final bool useBillingProfile;

  Map<String, dynamic> toMap() {
    if (!isTrader) return {'isTrader': false};
    return {
      'isTrader': true,
      'useBillingProfile': useBillingProfile,
      'name': name.trim(),
      'address': {
        ...address.toMap().map((k, v) => MapEntry(k, (v as String).trim())),
        'country': address.country.trim(),
      },
      'phone': phone.trim(),
      'email': email.trim(),
      if (idNumber.trim().isNotEmpty) 'idNumber': idNumber.trim(),
      if (tradeRegister.trim().isNotEmpty) 'tradeRegister': tradeRegister.trim(),
      if (tradeRegisterNumber.trim().isNotEmpty)
        'tradeRegisterNumber': tradeRegisterNumber.trim(),
      'selfCertified': selfCertified,
    };
  }
}

/// trader_public/{uid}: what guests see (never the ID number).
class TraderPublicInfo extends Equatable {
  const TraderPublicInfo({
    required this.isTrader,
    this.name = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.tradeRegister = '',
    this.tradeRegisterNumber = '',
  });

  static TraderPublicInfo? fromMap(Object? raw) {
    if (raw is! Map || raw['isTrader'] is! bool) return null;
    String s(String k) => (raw[k] as String?)?.trim() ?? '';
    return TraderPublicInfo(
      isTrader: raw['isTrader'] == true,
      name: s('name'),
      address: s('address'),
      phone: s('phone'),
      email: s('email'),
      tradeRegister: s('tradeRegister'),
      tradeRegisterNumber: s('tradeRegisterNumber'),
    );
  }

  final bool isTrader;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String tradeRegister;
  final String tradeRegisterNumber;

  @override
  List<Object?> get props =>
      [isTrader, name, address, phone, email, tradeRegister, tradeRegisterNumber];
}
