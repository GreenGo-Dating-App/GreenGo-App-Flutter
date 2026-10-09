import '../../../generated/app_localizations.dart';
import '../domain/entities/coin_package.dart';
import '../domain/entities/invoice.dart';

/// Localized display text for coin catalogue entities. The domain keeps
/// stable ids and English defaults; UI code uses these helpers.

/// Localized name of a [CoinSpendCategory].
String localizedCoinSpendCategory(
    AppLocalizations l10n, CoinSpendCategory category) {
  switch (category) {
    case CoinSpendCategory.matching:
      return l10n.coinSpendCategoryMatching;
    case CoinSpendCategory.messaging:
      return l10n.coinSpendCategoryMessaging;
    case CoinSpendCategory.profile:
      return l10n.profile;
    case CoinSpendCategory.gifts:
      return l10n.coinSpendCategoryGifts;
  }
}

/// Localized name of a [CoinSpendItem] (by `itemId`); falls back to the
/// stored name for admin-configured items.
String localizedCoinSpendItemName(AppLocalizations l10n, CoinSpendItem item) {
  switch (item.itemId) {
    case 'super_like':
      return l10n.tourSwipeHintSuper;
    case 'profile_boost':
      return l10n.boostFeatureName;
    case 'undo_swipe':
      return l10n.undoSwipe;
    case 'see_who_liked':
      return l10n.coinSpendSeeWhoLiked;
    case 'read_receipts_day':
      return l10n.coinSpendReadReceiptsDay;
    case 'gift_rose':
      return l10n.coinSpendRose;
    case 'gift_teddy':
      return l10n.coinSpendTeddyBear;
    case 'gift_diamond':
      return l10n.coinSpendDiamond;
    default:
      return item.name;
  }
}

/// Localized description of a [CoinSpendItem] (by `itemId`).
String localizedCoinSpendItemDescription(
    AppLocalizations l10n, CoinSpendItem item) {
  switch (item.itemId) {
    case 'super_like':
      return l10n.coinSpendSuperLikeDesc;
    case 'profile_boost':
      return l10n.coinSpendBoostDesc;
    case 'undo_swipe':
      return l10n.coinSpendUndoDesc;
    case 'see_who_liked':
      return l10n.coinSpendSeeWhoLikedDesc;
    case 'read_receipts_day':
      return l10n.coinSpendReadReceiptsDesc;
    case 'gift_rose':
      return l10n.coinSpendRoseDesc;
    case 'gift_teddy':
      return l10n.coinSpendTeddyBearDesc;
    case 'gift_diamond':
      return l10n.coinSpendDiamondDesc;
    default:
      return item.description;
  }
}

/// Localized savings badge for a promotional [CoinPackage], or null.
String? localizedCoinPackageSavings(AppLocalizations l10n, CoinPackage pkg) {
  if (pkg.bonusCoins != null && pkg.bonusCoins! > 0) {
    return l10n.shopBonusCoins(pkg.bonusCoins!);
  }
  if (pkg.discountPercentage != null && pkg.discountPercentage! > 0) {
    return l10n.shopSavePercent(pkg.discountPercentage!.toInt().toString());
  }
  return null;
}

/// Localized label of an invoice line, rendered from its stable `kind` (+
/// `coinCount`). Invoices written before `kind` existed show the stored
/// English `description`.
String localizedInvoiceLineItem(AppLocalizations l10n, InvoiceLineItem item) {
  switch (item.kind) {
    case InvoiceLineKind.coins:
      final count = item.coinCount;
      return count != null ? l10n.invoiceLineCoins(count) : item.description;
    case InvoiceLineKind.subscription:
      return l10n.invoiceLineSubscription;
    case InvoiceLineKind.gift:
      return l10n.invoiceLineGiftPackage;
    default:
      return item.description;
  }
}
