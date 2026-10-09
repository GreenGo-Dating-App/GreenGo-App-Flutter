import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/profile/domain/entities/profile.dart';
import 'effective_tier.dart';
import 'own_profile_store.dart';
import 'tier_entitlements.dart';

/// Who may charge money for an event / experience.
///
/// Only an ACTIVE business account (isBusiness + effective Platinum, see
/// [TierEntitlements.isBusinessActive]) may create paid events or paid
/// experiences. The server enforces the same rule (firestore.rules
/// `sellerBusinessActive`, createUserExperience / publishUserExperience,
/// createTicketCheckout, createBooking); this is the client mirror used to
/// hide the price / payment options in the wizards.
enum PaidListingAccess {
  /// Active business account: paid listings allowed.
  allowed,

  /// Business account whose Platinum lapsed: paid listings paused.
  businessPaused,

  /// Personal account: free listings only.
  notBusiness;

  bool get canSell => this == PaidListingAccess.allowed;

  static PaidListingAccess of(Profile? p) {
    if (p == null) return PaidListingAccess.notBusiness;
    if (TierEntitlements.isBusinessActive(p.effectiveTier, p.isBusiness)) {
      return PaidListingAccess.allowed;
    }
    return p.isBusiness
        ? PaidListingAccess.businessPaused
        : PaidListingAccess.notBusiness;
  }

  /// Same rule from a raw `profiles/{uid}` document.
  static PaidListingAccess ofDoc(Map<String, dynamic>? d) {
    if (d == null) return PaidListingAccess.notBusiness;
    final isBusiness = d['isBusiness'] == true;
    if (TierEntitlements.isBusinessActive(effectiveTierFromDoc(d), isBusiness)) {
      return PaidListingAccess.allowed;
    }
    return isBusiness
        ? PaidListingAccess.businessPaused
        : PaidListingAccess.notBusiness;
  }

  /// [uid]'s access: the cached own profile when it is the signed-in user,
  /// otherwise one read of `profiles/{uid}` (e.g. a co-owner editing the
  /// creator's event - the CREATOR must be the business). Fails closed
  /// (notBusiness) when the profile can't be read.
  static Future<PaidListingAccess> load(String uid) async {
    try {
      final own = OwnProfileStore.instance.peek(uid);
      if (own != null) return of(own);
      final doc =
          await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
      return ofDoc(doc.data());
    } catch (_) {
      return PaidListingAccess.notBusiness;
    }
  }
}
