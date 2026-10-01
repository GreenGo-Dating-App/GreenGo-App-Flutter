import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/features/user_experiences/domain/experience_limits.dart';
import 'package:greengo_chat/features/user_experiences/domain/experience_validation.dart';
import 'package:greengo_chat/features/user_experiences/domain/review_moderation.dart';

ExperienceDraft _draft({
  String title = 'Street food walk',
  String description =
      'Taste the best pastel and caldo de cana around the old market.',
  bool hasMainPhoto = true,
  int photoCount = 2,
  List<String> included = const ['Tastings'],
  List<String> notIncluded = const [],
  String locationName = 'Mercado Municipal',
  int? durationMinutes = 120,
  List<String> languages = const ['English'],
  int? maxGroupSize = 8,
  int? minGroupSize,
  bool isFree = false,
  double? price = 50,
  PaymentLinkType paymentType = PaymentLinkType.pix,
  String paymentValue = 'host@example.com',
  String meetingPoint = '',
}) =>
    ExperienceDraft(
      title: title,
      description: description,
      category: ExperienceCategory.foodDrink,
      hasMainPhoto: hasMainPhoto,
      photoCount: photoCount,
      included: included,
      notIncluded: notIncluded,
      locationName: locationName,
      durationMinutes: durationMinutes,
      languages: languages,
      maxGroupSize: maxGroupSize,
      minGroupSize: minGroupSize,
      isFree: isFree,
      price: price,
      paymentType: paymentType,
      paymentValue: paymentValue,
      meetingPoint: meetingPoint,
    );

void main() {
  group('ExperienceValidator', () {
    test('a complete draft is valid', () {
      expect(ExperienceValidator.validate(_draft()), isEmpty);
    });

    test('title and description lengths', () {
      expect(ExperienceValidator.validate(_draft(title: 'abcd')),
          contains(ExperienceFieldError.titleLength));
      expect(ExperienceValidator.validate(_draft(title: 'x' * 81)),
          contains(ExperienceFieldError.titleLength));
      expect(ExperienceValidator.validate(_draft(title: '  abcde  ')),
          isNot(contains(ExperienceFieldError.titleLength)));
      expect(ExperienceValidator.validate(_draft(description: 'too short')),
          contains(ExperienceFieldError.descriptionLength));
    });

    test('photos: main required, at most 8 extra', () {
      expect(ExperienceValidator.validate(_draft(hasMainPhoto: false)),
          contains(ExperienceFieldError.mainPhotoRequired));
      expect(ExperienceValidator.validate(_draft(photoCount: 9)),
          contains(ExperienceFieldError.tooManyPhotos));
      expect(ExperienceValidator.validate(_draft(photoCount: 8)), isEmpty);
    });

    test('included: at least one non-blank item, ≤ 20, each ≤ 120 chars', () {
      expect(ExperienceValidator.validate(_draft(included: const ['  ', ''])),
          contains(ExperienceFieldError.includedRequired));
      expect(
          ExperienceValidator.validate(
              _draft(included: List.filled(21, 'Item'))),
          contains(ExperienceFieldError.tooManyIncluded));
      expect(ExperienceValidator.validate(_draft(included: ['x' * 121])),
          contains(ExperienceFieldError.includedItemTooLong));
      expect(
          ExperienceValidator.validate(
              _draft(notIncluded: List.filled(21, 'Item'))),
          contains(ExperienceFieldError.tooManyNotIncluded));
    });

    test('location, duration, languages, group size', () {
      final errors = ExperienceValidator.validate(_draft(
        locationName: ' ',
        durationMinutes: 10,
        languages: const [],
        maxGroupSize: 0,
      ));
      expect(
          errors,
          containsAll([
            ExperienceFieldError.locationRequired,
            ExperienceFieldError.durationInvalid,
            ExperienceFieldError.languagesRequired,
            ExperienceFieldError.maxGroupInvalid,
          ]));
      expect(ExperienceValidator.validate(_draft(durationMinutes: null)),
          contains(ExperienceFieldError.durationInvalid));
      expect(
          ExperienceValidator.validate(
              _draft(minGroupSize: 9, maxGroupSize: 8)),
          contains(ExperienceFieldError.minGroupInvalid));
      expect(
          ExperienceValidator.validate(
              _draft(minGroupSize: 2, maxGroupSize: 8)),
          isEmpty);
    });

    test('price + payment link required unless free', () {
      expect(ExperienceValidator.validate(_draft(price: -1)),
          contains(ExperienceFieldError.priceInvalid));
      expect(ExperienceValidator.validate(_draft(paymentValue: '')),
          contains(ExperienceFieldError.paymentLinkRequired));
      expect(
          ExperienceValidator.validate(
              _draft(isFree: true, price: null, paymentValue: '')),
          isEmpty);
    });

    test('non-PIX payment links must be http(s) URLs', () {
      expect(
          ExperienceValidator.validate(_draft(
              paymentType: PaymentLinkType.paypal, paymentValue: 'paypal.me/x')),
          contains(ExperienceFieldError.paymentLinkInvalid));
      expect(
          ExperienceValidator.validate(_draft(
              paymentType: PaymentLinkType.paypal,
              paymentValue: 'https://paypal.me/ana')),
          isEmpty);
      // PIX keys are free text (email / phone / CPF / random key).
      expect(
          ExperienceValidator.validate(_draft(
              paymentType: PaymentLinkType.pix, paymentValue: '+5511999999999')),
          isEmpty);
    });

    test('a Venmo @handle becomes its profile link', () {
      expect(
          ExperienceValidator.normalizePaymentValue(
              PaymentLinkType.venmo, ' @ana-b '),
          'https://venmo.com/u/ana-b');
      expect(
          ExperienceValidator.validate(_draft(
              paymentType: PaymentLinkType.venmo, paymentValue: '@ana')),
          isEmpty);
    });

    test('prohibited language anywhere blocks the form', () {
      expect(ExperienceValidator.validate(_draft(title: 'Best shit tour')),
          contains(ExperienceFieldError.prohibitedText));
      expect(
          ExperienceValidator.validate(_draft(included: const ['porn'])),
          contains(ExperienceFieldError.prohibitedText));
      expect(
          ExperienceValidator.validate(_draft(meetingPoint: 'Scunthorpe')),
          isEmpty);
    });

    test('search keywords: lower-cased, deduplicated, split on punctuation', () {
      expect(buildExperienceKeywords(['Hello, World!', 'hello', null, 'a']),
          ['hello', 'world']);
    });
  });

  group('ReviewModeration (client-side decision)', () {
    const max = ExperienceLimits.reviewMax;
    test('ok / empty / too long', () {
      expect(ReviewModeration.check('Lovely evening', maxLength: max),
          CommentVerdict.ok);
      expect(ReviewModeration.check('   ', maxLength: max), CommentVerdict.empty);
      expect(ReviewModeration.check('', maxLength: max, allowEmpty: true),
          CommentVerdict.ok);
      expect(ReviewModeration.check('x' * 1001, maxLength: max),
          CommentVerdict.tooLong);
    });

    test('prohibited terms and links are rejected', () {
      expect(ReviewModeration.check('What a bitch', maxLength: max),
          CommentVerdict.prohibited);
      expect(ReviewModeration.check('see https://spam.example', maxLength: max),
          CommentVerdict.containsLink);
      expect(ReviewModeration.check('visit www.spam.example', maxLength: max),
          CommentVerdict.containsLink);
      // Prohibited language is the reason reported when both apply.
      expect(ReviewModeration.check('shit www.spam.example', maxLength: max),
          CommentVerdict.prohibited);
    });
  });

  group('experience limits per effective tier', () {
    test('FREE 1 · SILVER 5 · GOLD 10 · PLATINUM/TEST ∞ · admin ∞', () {
      expect(experienceLimitFor(MembershipTier.free), 1);
      expect(experienceLimitFor(MembershipTier.silver), 5);
      expect(experienceLimitFor(MembershipTier.gold), 10);
      expect(experienceLimitFor(MembershipTier.platinum), isNull);
      expect(experienceLimitFor(MembershipTier.test), isNull);
      expect(experienceLimitFor(MembershipTier.free, isAdmin: true), isNull);
    });

    test('creation allowed only below the limit; downgraded hosts keep theirs', () {
      expect(
          canCreateAnotherExperience(tier: MembershipTier.free, count: 0),
          isTrue);
      expect(
          canCreateAnotherExperience(tier: MembershipTier.free, count: 1),
          isFalse);
      expect(
          canCreateAnotherExperience(tier: MembershipTier.silver, count: 4),
          isTrue);
      expect(
          canCreateAnotherExperience(tier: MembershipTier.silver, count: 5),
          isFalse);
      // Was Gold with 10, now Silver: blocked (nothing is auto-hidden).
      expect(
          canCreateAnotherExperience(tier: MembershipTier.silver, count: 10),
          isFalse);
      expect(
          canCreateAnotherExperience(tier: MembershipTier.platinum, count: 99),
          isTrue);
    });

    test('suggests the cheapest tier that allows one more', () {
      // The paid tier to upgrade to once the current one is full.
      expect(tierNeededForExperiences(1), MembershipTier.silver);
      expect(tierNeededForExperiences(5), MembershipTier.gold);
      expect(tierNeededForExperiences(10), MembershipTier.platinum);
    });
  });
}
