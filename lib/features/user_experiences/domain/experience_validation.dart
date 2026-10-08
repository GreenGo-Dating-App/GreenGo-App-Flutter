import '../../../core/services/content_filter_service.dart';
import 'contact_info.dart';
import 'entities/user_experience.dart';

/// Field limits — mirrored by functions/src/user_experiences/validation.ts and
/// firestore.rules. Change all three together.
class ExperienceLimits {
  const ExperienceLimits._();

  static const int titleMin = 5;
  static const int titleMax = 80;
  static const int descriptionMin = 30;
  static const int descriptionMax = 2000;
  static const int maxPhotos = 8; // gallery, besides the main photo
  static const int includedMax = 20;
  static const int notIncludedMax = 20;
  static const int itemMax = 120;
  static const int durationMin = 15;
  static const int durationMax = 60 * 24 * 14;
  static const int groupMax = 500;
  static const double priceMax = 1000000;
  static const int shortTextMax = 500;
  static const int locationMax = 200;
  static const int paymentValueMax = 300;
  static const int languagesMax = 10;
  static const int cancellationNotesMax = 300;
  static const int reviewMax = 1000;
  static const int replyMax = 500;
  static const int mentionsMax = 10;
}

/// One reason a form can't be saved. The UI maps each to a localized string.
enum ExperienceFieldError {
  titleLength,
  descriptionLength,
  mainPhotoRequired,
  tooManyPhotos,
  includedRequired,
  tooManyIncluded,
  includedItemTooLong,
  tooManyNotIncluded,
  notIncludedItemTooLong,
  locationRequired,
  durationInvalid,
  languagesRequired,
  maxGroupInvalid,
  minGroupInvalid,
  priceInvalid,
  paymentLinkRequired,
  paymentLinkInvalid,

  /// Paid experience without any payment method (cash / link).
  paymentMethodsRequired,
  prohibitedText,

  /// Phone / e-mail / handle / PIX key / "pay me on…" outside the payment
  /// link (anti-scam).
  contactInfo,
}

/// Raw values of the create/edit form (what validation looks at).
class ExperienceDraft {
  const ExperienceDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.hasMainPhoto,
    required this.photoCount,
    required this.included,
    required this.notIncluded,
    required this.locationName,
    required this.durationMinutes,
    required this.languages,
    required this.maxGroupSize,
    this.minGroupSize,
    this.meetingPoint = '',
    this.availability = '',
    this.cancellationNotes = '',
    this.isFree = false,
    this.price,
    this.paymentType = PaymentLinkType.pix,
    this.paymentValue = '',
    this.paymentMethods = const {PaymentMethod.link},
    this.ticketProviderComplete = true,
  });

  /// In-app tickets ([PaymentMethod.online]): a provider (and, for manual
  /// confirmation, a method) is chosen.
  final bool ticketProviderComplete;

  final String title;
  final String description;
  final ExperienceCategory category;
  final bool hasMainPhoto;
  final int photoCount;
  final List<String> included;
  final List<String> notIncluded;
  final String locationName;
  final int? durationMinutes;
  final List<String> languages;
  final int? maxGroupSize;
  final int? minGroupSize;
  final String meetingPoint;
  final String availability;
  final String cancellationNotes;
  final bool isFree;
  final double? price;
  final PaymentLinkType paymentType;
  final String paymentValue;

  /// Cash at the meeting and/or the online link (paid experiences).
  final Set<PaymentMethod> paymentMethods;
}

/// Pure validation for the experience form (unit tested).
class ExperienceValidator {
  const ExperienceValidator._();

  static final RegExp _url = RegExp(r'^https?://[^\s/$.?#][^\s]*$',
      caseSensitive: false);

  static bool isHttpUrl(String v) => _url.hasMatch(v.trim());

  static ExperienceFieldError? title(String v) {
    final t = v.trim();
    return t.length < ExperienceLimits.titleMin ||
            t.length > ExperienceLimits.titleMax
        ? ExperienceFieldError.titleLength
        : null;
  }

  static ExperienceFieldError? description(String v) {
    final t = v.trim();
    return t.length < ExperienceLimits.descriptionMin ||
            t.length > ExperienceLimits.descriptionMax
        ? ExperienceFieldError.descriptionLength
        : null;
  }

  /// Normalises a payment value for storage: trims; a Venmo `@handle` becomes
  /// its profile URL. PIX keys are kept as typed.
  static String normalizePaymentValue(PaymentLinkType type, String raw) {
    final v = raw.trim();
    if (type == PaymentLinkType.venmo && v.startsWith('@') && v.length > 1) {
      return 'https://venmo.com/u/${v.substring(1)}';
    }
    return v;
  }

  static ExperienceFieldError? paymentLink(
      bool isFree, PaymentLinkType type, String raw) {
    final v = normalizePaymentValue(type, raw);
    if (v.isEmpty) return isFree ? null : ExperienceFieldError.paymentLinkRequired;
    if (v.length > ExperienceLimits.paymentValueMax) {
      return ExperienceFieldError.paymentLinkInvalid;
    }
    if (type != PaymentLinkType.pix && !isHttpUrl(v)) {
      return ExperienceFieldError.paymentLinkInvalid;
    }
    return null;
  }

  /// Every problem with [d], in form order. Empty = valid.
  static List<ExperienceFieldError> validate(ExperienceDraft d) {
    final errors = <ExperienceFieldError>[];
    void add(ExperienceFieldError? e) {
      if (e != null && !errors.contains(e)) errors.add(e);
    }

    add(title(d.title));
    add(description(d.description));
    if (!d.hasMainPhoto) add(ExperienceFieldError.mainPhotoRequired);
    if (d.photoCount > ExperienceLimits.maxPhotos) {
      add(ExperienceFieldError.tooManyPhotos);
    }

    final inc = _clean(d.included);
    if (inc.isEmpty) add(ExperienceFieldError.includedRequired);
    if (inc.length > ExperienceLimits.includedMax) {
      add(ExperienceFieldError.tooManyIncluded);
    }
    if (inc.any((i) => i.length > ExperienceLimits.itemMax)) {
      add(ExperienceFieldError.includedItemTooLong);
    }
    final notInc = _clean(d.notIncluded);
    if (notInc.length > ExperienceLimits.notIncludedMax) {
      add(ExperienceFieldError.tooManyNotIncluded);
    }
    if (notInc.any((i) => i.length > ExperienceLimits.itemMax)) {
      add(ExperienceFieldError.notIncludedItemTooLong);
    }

    final loc = d.locationName.trim();
    if (loc.isEmpty || loc.length > ExperienceLimits.locationMax) {
      add(ExperienceFieldError.locationRequired);
    }
    final dur = d.durationMinutes;
    if (dur == null ||
        dur < ExperienceLimits.durationMin ||
        dur > ExperienceLimits.durationMax) {
      add(ExperienceFieldError.durationInvalid);
    }
    if (d.languages.isEmpty) add(ExperienceFieldError.languagesRequired);

    final max = d.maxGroupSize;
    if (max == null || max < 1 || max > ExperienceLimits.groupMax) {
      add(ExperienceFieldError.maxGroupInvalid);
    }
    final min = d.minGroupSize;
    if (min != null && (min < 1 || (max != null && min > max))) {
      add(ExperienceFieldError.minGroupInvalid);
    }

    if (!d.isFree) {
      final p = d.price;
      if (p == null || p < 0 || p > ExperienceLimits.priceMax) {
        add(ExperienceFieldError.priceInvalid);
      }
    }
    // Paid: at least one method; the link is required only when chosen.
    // Free: no payment at all.
    if (!d.isFree) {
      if (d.paymentMethods.isEmpty) {
        add(ExperienceFieldError.paymentMethodsRequired);
      }
      if (d.paymentMethods.contains(PaymentMethod.online)) {
        if (!d.ticketProviderComplete) add(ExperienceFieldError.paymentMethodsRequired);
      } else if (d.paymentMethods.contains(PaymentMethod.link)) {
        add(paymentLink(false, d.paymentType, d.paymentValue));
      }
    }

    if (prohibitedTerms(d).isNotEmpty) add(ExperienceFieldError.prohibitedText);
    if (hasContactInfo(d)) add(ExperienceFieldError.contactInfo);
    return errors;
  }

  /// Every free-text field the server moderates (NOT the payment link).
  static List<String> _texts(ExperienceDraft d) => [
        d.title,
        d.description,
        d.meetingPoint,
        d.availability,
        d.cancellationNotes,
        ...d.included,
        ...d.notIncluded,
      ];

  /// Off-platform contact / payment info in any moderated field.
  static bool hasContactInfo(ExperienceDraft d) =>
      _texts(d).any(ContactInfoDetector.contains);

  /// Prohibited terms across every free-text field of the form.
  static List<String> prohibitedTerms(ExperienceDraft d) {
    final filter = ContentFilterService();
    final hits = <String>{};
    for (final t in _texts(d)) {
      hits.addAll(filter.findProhibitedTerms(t));
    }
    return hits.toList();
  }

  static List<String> _clean(List<String> items) =>
      items.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// Cleaned list for storage (trimmed, empties dropped).
  static List<String> cleanItems(List<String> items) => _clean(items);
}

/// Lower-cased search tokens (title, city, country, category, location).
/// Same split as the server (`buildSearchKeywords`): whitespace + ASCII
/// punctuation; tokens ≥ 2 chars; ≤ 40 tokens.
List<String> buildExperienceKeywords(List<String?> parts) {
  final out = <String>{};
  final split = RegExp(r'[\s!-/:-@\[-`{-~]+');
  for (final p in parts) {
    if (p == null) continue;
    for (final t in p.toLowerCase().split(split)) {
      if (t.length >= 2) out.add(t);
      if (out.length >= 40) return out.toList();
    }
  }
  return out.toList();
}
