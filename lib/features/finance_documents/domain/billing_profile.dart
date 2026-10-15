import 'package:equatable/equatable.dart';

/// Seller "invoice details" — the fiscal customer data of GreenGo's fee
/// invoices / NFS-e (functions/src/finance/billing.ts is authoritative: it
/// validates every field and the tax-id checksums; this side only mirrors the
/// labels and which fields are required, so the form can guide the user).
enum BillingType { private, company }

BillingType? billingTypeFrom(Object? v) => switch (v) {
      'private' => BillingType.private,
      'company' => BillingType.company,
      _ => null,
    };

String billingTypeName(BillingType t) => t == BillingType.company ? 'company' : 'private';

class BillingAddress extends Equatable {
  const BillingAddress({
    this.street = '',
    this.number = '',
    this.complement = '',
    this.district = '',
    this.city = '',
    this.region = '',
    this.postalCode = '',
    this.country = '',
  });

  factory BillingAddress.fromMap(Map<dynamic, dynamic> m) {
    String s(String k) => (m[k] as String?)?.trim() ?? '';
    return BillingAddress(
      street: s('street'),
      number: s('number'),
      complement: s('complement'),
      district: s('district'),
      city: s('city'),
      region: s('region'),
      postalCode: s('postalCode'),
      country: s('country'),
    );
  }

  final String street;
  final String number;
  final String complement;
  final String district;
  final String city;
  final String region;
  final String postalCode;
  final String country;

  Map<String, dynamic> toMap() => {
        'street': street,
        'number': number,
        'complement': complement,
        'district': district,
        'city': city,
        'region': region,
        'postalCode': postalCode,
      };

  @override
  List<Object?> get props => [street, number, complement, district, city, region, postalCode, country];
}

/// The saved profile as the owner sees it: the tax id only MASKED.
class BillingProfile extends Equatable {
  const BillingProfile({
    required this.type,
    required this.country,
    this.legalName = '',
    this.tradeName = '',
    this.contactPerson = '',
    this.taxIdMasked = '',
    this.taxIdKind,
    this.hasTaxId = false,
    this.inscricaoMunicipal = '',
    this.inscricaoEstadual = '',
    this.address,
    this.email = '',
    this.phone = '',
    this.updatedAt,
  });

  /// Null when the map has no usable type / country (e.g. an old admin-only doc).
  static BillingProfile? fromMap(Object? raw) {
    if (raw is! Map) return null;
    String s(String k) => (raw[k] as String?)?.trim() ?? '';
    final type = billingTypeFrom(raw['type']);
    final country = s('country').toUpperCase();
    final addr = raw['address'];
    return BillingProfile(
      type: type ?? BillingType.private,
      country: country,
      legalName: s('legalName'),
      tradeName: s('tradeName'),
      contactPerson: s('contactPerson'),
      taxIdMasked: s('taxIdMasked'),
      taxIdKind: raw['taxIdKind'] as String?,
      hasTaxId: raw['hasTaxId'] == true,
      inscricaoMunicipal: s('inscricaoMunicipal'),
      inscricaoEstadual: s('inscricaoEstadual'),
      address: addr is Map ? BillingAddress.fromMap(addr) : null,
      email: s('email'),
      phone: s('phone'),
      updatedAt: DateTime.tryParse(s('updatedAt')),
    );
  }

  final BillingType type;
  final String country;
  final String legalName;
  final String tradeName;
  final String contactPerson;
  final String taxIdMasked;
  final String? taxIdKind;
  final bool hasTaxId;
  final String inscricaoMunicipal;
  final String inscricaoEstadual;
  final BillingAddress? address;
  final String email;
  final String phone;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        type, country, legalName, tradeName, contactPerson, taxIdMasked, taxIdKind, hasTaxId,
        inscricaoMunicipal, inscricaoEstadual, address, email, phone, updatedAt,
      ];
}

/// getMyBillingProfile / saveMyBillingProfile result.
class BillingStatus extends Equatable {
  const BillingStatus({this.profile, this.missing = const <String>[], this.complete = false});

  factory BillingStatus.fromMap(Map<dynamic, dynamic> m) => BillingStatus(
        profile: BillingProfile.fromMap(m['profile']),
        missing: [for (final x in (m['missing'] as List? ?? const [])) if (x is String) x],
        complete: m['complete'] == true,
      );

  final BillingProfile? profile;
  final List<String> missing;
  final bool complete;

  @override
  List<Object?> get props => [profile, missing, complete];
}

enum BillingErrorCode { required, invalid, tooLong }

/// A server validation error on one field (`details: { field, code }`).
class BillingFieldError extends Equatable {
  const BillingFieldError(this.field, this.code);

  /// Parses the `details` of an `invalid-argument` callable error; null otherwise.
  static BillingFieldError? fromDetails(Object? details) {
    if (details is! Map) return null;
    final field = details['field'];
    if (field is! String || field.isEmpty) return null;
    final code = switch (details['code']) {
      'required' => BillingErrorCode.required,
      'tooLong' => BillingErrorCode.tooLong,
      _ => BillingErrorCode.invalid,
    };
    return BillingFieldError(field, code);
  }

  final String field;
  final BillingErrorCode code;

  @override
  List<Object?> get props => [field, code];
}

/// What the form sends. [taxId] is sent only when the user typed a new one
/// (blank keeps the stored id on the server — the client only has it masked).
class BillingDraft {
  const BillingDraft({
    required this.type,
    required this.country,
    required this.legalName,
    required this.address,
    required this.email,
    this.tradeName = '',
    this.contactPerson = '',
    this.taxId = '',
    this.inscricaoMunicipal = '',
    this.inscricaoEstadual = '',
    this.phone = '',
  });

  final BillingType type;
  final String country;
  final String legalName;
  final String tradeName;
  final String contactPerson;
  final String taxId;
  final String inscricaoMunicipal;
  final String inscricaoEstadual;
  final BillingAddress address;
  final String email;
  final String phone;

  Map<String, dynamic> toMap() {
    final company = type == BillingType.company;
    final br = country == 'BR';
    return {
      'type': billingTypeName(type),
      'country': country,
      'legalName': legalName.trim(),
      if (company) 'tradeName': tradeName.trim(),
      if (company) 'contactPerson': contactPerson.trim(),
      if (taxId.trim().isNotEmpty) 'taxId': taxId.trim(),
      if (company && br) 'inscricaoMunicipal': inscricaoMunicipal.trim(),
      if (company && br) 'inscricaoEstadual': inscricaoEstadual.trim(),
      'address': address.toMap().map((k, v) => MapEntry(k, (v as String).trim())),
      'email': email.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    };
  }
}

/// Which tax-id label the form shows (mirrors validateTaxId on the server).
enum TaxIdLabel {
  cpf, cnpj, codiceFiscale, partitaIva, nifPt, nipc, nifNie, cifNif, steuerId, frSpi, ssnItin, ein, vat, generic, genericCompany,
}

const Set<String> kEuCountries = {
  'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'GR', 'ES', 'FI', 'FR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU',
  'LV', 'MT', 'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK',
};

TaxIdLabel taxIdLabelFor(String country, BillingType type) {
  final company = type == BillingType.company;
  switch (country) {
    case 'BR':
      return company ? TaxIdLabel.cnpj : TaxIdLabel.cpf;
    case 'IT':
      return company ? TaxIdLabel.partitaIva : TaxIdLabel.codiceFiscale;
    case 'PT':
      return company ? TaxIdLabel.nipc : TaxIdLabel.nifPt;
    case 'ES':
      return company ? TaxIdLabel.cifNif : TaxIdLabel.nifNie;
    case 'DE':
      return company ? TaxIdLabel.vat : TaxIdLabel.steuerId;
    case 'FR':
      return company ? TaxIdLabel.vat : TaxIdLabel.frSpi;
    case 'US':
      return company ? TaxIdLabel.ein : TaxIdLabel.ssnItin;
    default:
      if (company) return kEuCountries.contains(country) ? TaxIdLabel.vat : TaxIdLabel.genericCompany;
      return TaxIdLabel.generic;
  }
}

/// US private persons may leave the SSN / ITIN empty (sensitive, not needed).
bool taxIdOptional(String country, BillingType type) => country == 'US' && type == BillingType.private;
bool numberRequired(String country) => country == 'BR';
bool districtRequired(String country) => country == 'BR';
bool regionRequired(String country) => country == 'BR' || country == 'US';

/// Postal-code shape shown as a hint (null = no fixed format).
String? postalCodeHint(String country) => switch (country) {
      'BR' => '00000-000',
      'PT' => '0000-000',
      'US' || 'IT' || 'ES' || 'DE' || 'FR' => '00000',
      _ => null,
    };

/// Shown first in the country picker; the rest follow alphabetically.
const List<String> kPriorityBillingCountries = ['BR', 'IT', 'PT', 'ES', 'DE', 'FR', 'US'];
