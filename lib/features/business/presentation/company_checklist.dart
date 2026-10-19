import '../../profile/domain/entities/profile.dart';

/// The company information a business must (or may) fill in, shown in the
/// Business Center Settings tab (owner request 2026-10-15: "a settings page
/// where the user must fill information about the company").
enum CompanyItem {
  name(required: true),
  category(required: true),
  description(required: true),
  // Owner 2026-10-19: the BUSINESS PROFILE PICTURE (businessLogoUrl), the
  // business's own picture (Discover tile, storefront avatar, chat avatar).
  // The storefront featured image (coverImageUrl) is optional.
  storefrontPhoto(required: true),
  address(required: true),
  invoiceDetails(required: true),
  payments(required: true),
  // Terms 12.4 / DSA art. 30: sellers say whether they act as a trader.
  traderStatus(required: true),
  hours(required: false),
  contact(required: false),
  verification(required: false);

  const CompanyItem({required this.required});
  final bool required;
}

/// Which items are done for [p]. [billingComplete] / [paymentsConnected] /
/// [traderDeclared] are null while unknown (not loaded yet): such items count
/// as not missing, so nothing flashes as missing during loading.
Map<CompanyItem, bool?> companyChecklist(Profile p,
    {bool? billingComplete, bool? paymentsConnected, bool? traderDeclared}) {
  bool has(String? v) => (v ?? '').trim().isNotEmpty;
  final links = p.socialLinks;
  final anyContact = has(p.businessWhatsapp) ||
      p.storefrontLinks.any((l) => l.trim().isNotEmpty) ||
      (links != null &&
          [links.instagram, links.facebook, links.tiktok, links.linkedin, links.x].any(has));
  return {
    CompanyItem.name: has(p.businessName),
    CompanyItem.category: has(p.businessCategory),
    CompanyItem.description: has(p.storefrontBio),
    CompanyItem.storefrontPhoto: has(p.businessLogoUrl),
    CompanyItem.address: p.businessAddress != null,
    CompanyItem.invoiceDetails: billingComplete,
    CompanyItem.payments: paymentsConnected,
    CompanyItem.traderStatus: traderDeclared,
    CompanyItem.hours: p.openingHours.isNotEmpty,
    CompanyItem.contact: anyContact,
    CompanyItem.verification: p.businessVerified,
  };
}

/// Required items known to be missing.
List<CompanyItem> missingRequired(Map<CompanyItem, bool?> c) =>
    [for (final e in c.entries) if (e.key.required && e.value == false) e.key];
