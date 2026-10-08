import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../generated/app_localizations.dart';
import '../domain/cancellation_rules.dart';
import '../domain/entities/user_experience.dart';
import '../domain/experience_validation.dart';
import '../../profile/presentation/screens/onboarding/onboarding_value_labels.dart';

/// Localized labels / formatting for the user-experiences feature.
class ExperienceL10n {
  const ExperienceL10n._();

  /// Localized name for a stored (English) language value from
  /// [kExperienceLanguages]; unknown values are shown as stored.
  static String language(AppLocalizations l, String value) {
    switch (value) {
      case 'Hebrew':
        return l.uexpLangHebrew;
      case 'Thai':
        return l.uexpLangThai;
      case 'Vietnamese':
        return l.uexpLangVietnamese;
      default:
        return localizedOnboardingLanguage(l, value);
    }
  }

  static String category(AppLocalizations l, ExperienceCategory c) {
    switch (c) {
      case ExperienceCategory.foodDrink:
        return l.uexpCatFoodDrink;
      case ExperienceCategory.cultureHistory:
        return l.uexpCatCultureHistory;
      case ExperienceCategory.natureOutdoors:
        return l.uexpCatNatureOutdoors;
      case ExperienceCategory.nightlife:
        return l.uexpCatNightlife;
      case ExperienceCategory.sportsAdventure:
        return l.uexpCatSportsAdventure;
      case ExperienceCategory.wellness:
        return l.uexpCatWellness;
      case ExperienceCategory.languageLearning:
        return l.uexpCatLanguageLearning;
      case ExperienceCategory.toursWalks:
        return l.uexpCatToursWalks;
      case ExperienceCategory.workshopsClasses:
        return l.uexpCatWorkshopsClasses;
      case ExperienceCategory.other:
        return l.uexpCatOther;
    }
  }

  static IconData categoryIcon(ExperienceCategory c) {
    switch (c) {
      case ExperienceCategory.foodDrink:
        return Icons.restaurant;
      case ExperienceCategory.cultureHistory:
        return Icons.account_balance;
      case ExperienceCategory.natureOutdoors:
        return Icons.park;
      case ExperienceCategory.nightlife:
        return Icons.nightlife;
      case ExperienceCategory.sportsAdventure:
        return Icons.hiking;
      case ExperienceCategory.wellness:
        return Icons.spa;
      case ExperienceCategory.languageLearning:
        return Icons.translate;
      case ExperienceCategory.toursWalks:
        return Icons.directions_walk;
      case ExperienceCategory.workshopsClasses:
        return Icons.palette;
      case ExperienceCategory.other:
        return Icons.explore;
    }
  }

  static String paymentType(AppLocalizations l, PaymentLinkType t) {
    switch (t) {
      case PaymentLinkType.pix:
        return l.uexpPayPix;
      case PaymentLinkType.paypal:
        return l.uexpPayPaypal;
      case PaymentLinkType.venmo:
        return l.uexpPayVenmo;
      case PaymentLinkType.stripe:
        return l.uexpPayStripe;
      case PaymentLinkType.other:
        return l.uexpPayOther;
    }
  }

  static String status(AppLocalizations l, ExperienceStatus s) {
    switch (s) {
      case ExperienceStatus.draft:
        return l.uexpStatusDraft;
      case ExperienceStatus.published:
        return l.uexpStatusPublished;
      case ExperienceStatus.hidden:
        return l.uexpStatusHidden;
    }
  }

  static String fieldError(AppLocalizations l, ExperienceFieldError e) {
    switch (e) {
      case ExperienceFieldError.titleLength:
        return l.uexpErrTitle(ExperienceLimits.titleMin, ExperienceLimits.titleMax);
      case ExperienceFieldError.descriptionLength:
        return l.uexpErrDescription(
            ExperienceLimits.descriptionMin, ExperienceLimits.descriptionMax);
      case ExperienceFieldError.mainPhotoRequired:
        return l.uexpErrMainPhoto;
      case ExperienceFieldError.tooManyPhotos:
        return l.uexpErrTooManyPhotos(ExperienceLimits.maxPhotos);
      case ExperienceFieldError.includedRequired:
        return l.uexpErrIncluded;
      case ExperienceFieldError.tooManyIncluded:
        return l.uexpErrTooManyItems(ExperienceLimits.includedMax);
      case ExperienceFieldError.tooManyNotIncluded:
        return l.uexpErrTooManyItems(ExperienceLimits.notIncludedMax);
      case ExperienceFieldError.includedItemTooLong:
      case ExperienceFieldError.notIncludedItemTooLong:
        return l.uexpErrItemTooLong(ExperienceLimits.itemMax);
      case ExperienceFieldError.locationRequired:
        return l.uexpErrLocation;
      case ExperienceFieldError.durationInvalid:
        return l.uexpErrDuration;
      case ExperienceFieldError.languagesRequired:
        return l.uexpErrLanguages;
      case ExperienceFieldError.maxGroupInvalid:
        return l.uexpErrMaxGroup(ExperienceLimits.groupMax);
      case ExperienceFieldError.minGroupInvalid:
        return l.uexpErrMinGroup;
      case ExperienceFieldError.priceInvalid:
        return l.uexpErrPrice;
      case ExperienceFieldError.paymentLinkRequired:
        return l.uexpErrPaymentRequired;
      case ExperienceFieldError.paymentLinkInvalid:
        return l.uexpErrPaymentInvalid;
      case ExperienceFieldError.prohibitedText:
        return l.uexpErrProhibited;
      case ExperienceFieldError.contactInfo:
        return l.uexpErrContactInfo;
      case ExperienceFieldError.paymentMethodsRequired:
        return l.uexpErrPaymentMethods;
    }
  }

  static String policy(AppLocalizations l, CancellationPolicy p) => switch (p) {
        CancellationPolicy.flexible => l.uexpPolicyFlexible,
        CancellationPolicy.moderate => l.uexpPolicyModerate,
        CancellationPolicy.strict => l.uexpPolicyStrict,
      };

  static String policyDescription(AppLocalizations l, CancellationPolicy p) =>
      switch (p) {
        CancellationPolicy.flexible => l.uexpPolicyFlexibleDesc,
        CancellationPolicy.moderate => l.uexpPolicyModerateDesc,
        CancellationPolicy.strict => l.uexpPolicyStrictDesc,
      };

  static String cancelWindow(AppLocalizations l, CancelWindow w) => switch (w) {
        CancelWindow.moreThan7Days => l.uexpPolicyMoreThan7d,
        CancelWindow.between7DaysAnd24h => l.uexpPolicy7dTo24h,
        CancelWindow.moreThan24h => l.uexpPolicyMoreThan24h,
        CancelWindow.lessThan24h => l.uexpPolicyLess24h,
        CancelWindow.lessThan7Days => l.uexpPolicyLess7d,
      };

  static String paymentMethod(AppLocalizations l, PaymentMethod m) =>
      switch (m) {
        PaymentMethod.cash => l.uexpMethodCash,
        PaymentMethod.link => l.uexpMethodLink,
        PaymentMethod.online => l.tpPayInApp,
      };

  static IconData paymentMethodIcon(PaymentMethod m) => switch (m) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.link => Icons.link_rounded,
        PaymentMethod.online => Icons.lock_outline,
      };

  /// Localized percentage ("100%", "50 %" …).
  static String percent(BuildContext context, double fraction) {
    final locale = Localizations.localeOf(context).toString();
    try {
      return NumberFormat.percentPattern(locale).format(fraction);
    } catch (_) {
      return NumberFormat.percentPattern().format(fraction);
    }
  }

  /// "2 h 30 min" / "45 min" / "3 h".
  static String duration(AppLocalizations l, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l.uexpDurationMinutes(m);
    if (m == 0) return l.uexpDurationHours(h);
    return '${l.uexpDurationHours(h)} ${l.uexpDurationMinutes(m)}';
  }

  static String groupSize(AppLocalizations l, int? min, int max) =>
      min != null && min > 0 && min < max
          ? l.uexpGroupSizeRange(min, max)
          : l.uexpGroupUpTo(max);

  /// "R$ 50" / "€12.50" / "Free".
  static String price(AppLocalizations l, UserExperience e) {
    if (e.isFree || e.price <= 0) return l.uexpFree;
    final p = e.price == e.price.roundToDouble()
        ? e.price.toStringAsFixed(0)
        : e.price.toStringAsFixed(2);
    final c = e.currency ?? '';
    return c.isEmpty ? p : '$c $p';
  }

  /// Localized date (e.g. "12 Mar 2026").
  static String date(BuildContext context, DateTime? d) {
    if (d == null) return '';
    final locale = Localizations.localeOf(context).toString();
    try {
      return DateFormat.yMMMd(locale).format(d);
    } catch (_) {
      return DateFormat.yMMMd().format(d);
    }
  }
}
