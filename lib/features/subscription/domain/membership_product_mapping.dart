import '../../../core/constants/product_catalog.dart';
import 'entities/subscription.dart';

/// [SubscriptionTier] for a membership product ID (canonical, iOS or Play),
/// via the shared [ProductCatalog.classify]. Base maps to
/// [SubscriptionTier.basic] — Base is an access membership, not a tier.
SubscriptionTier subscriptionTierForProduct(String productId) {
  switch (ProductCatalog.classify(productId).tier) {
    case MembershipProductTier.platinum:
      return SubscriptionTier.platinum;
    case MembershipProductTier.gold:
      return SubscriptionTier.gold;
    case MembershipProductTier.silver:
      return SubscriptionTier.silver;
    case MembershipProductTier.base:
      return SubscriptionTier.basic;
  }
}
