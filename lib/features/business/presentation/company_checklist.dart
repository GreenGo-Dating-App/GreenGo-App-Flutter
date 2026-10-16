import '../../profile/domain/entities/profile.dart';

/// The company information a business must (or may) fill in, shown in the
/// Business Center Settings tab (owner request 2026-10-15: "a settings page
/// where the user must fill information about the company").
enum CompanyItem {
  name(required: true),
  category(required: true),
  description(required: true),
  address(required: true),
  invoiceDetails(required: true),
  payments(required: true),
  hours(required: false),
  contact(required: false),
  cover(required: false),
  verification(required: false);

  const CompanyItem({required this.required});
  final bool required;
}

/// Which items are done for [p]. [billingComplete] / [paymentsConnected]
/// are null while unknown (not loaded yet): such items count as not missing,
/// so nothing flashes as missing during loading.
Map<CompanyItem, bool?> companyChecklist(Profile p, {bool? billingComplete, bool? paymentsConnected}) {
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
    CompanyItem.address: p.businessAddress != null,
    CompanyItem.invoiceDetails: billingComplete,
    CompanyItem.payments: paymentsConnected,
    CompanyItem.hours: p.openingHours.isNotEmpty,
    CompanyItem.contact: anyContact,
    CompanyItem.cover: has(p.coverImageUrl),
    CompanyItem.verification: p.businessVerified,
  };
}

/// Required items known to be missing.
List<CompanyItem> missingRequired(Map<CompanyItem, bool?> c) =>
    [for (final e in c.entries) if (e.key.required && e.value == false) e.key];
