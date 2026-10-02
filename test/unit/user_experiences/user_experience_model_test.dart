import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/user_experiences/data/models/user_experience_model.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/experience_review.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';

UserExperience _sample() => UserExperience(
      id: 'exp1',
      hostId: 'host1',
      hostName: 'Ana',
      hostPhotoUrl: 'https://cdn.example.com/ana.jpg',
      title: 'Street food walk',
      description: 'Taste the best pastel and caldo de cana around the old market.',
      category: ExperienceCategory.foodDrink,
      mainPhotoUrl: 'https://cdn.example.com/main.jpg',
      photoUrls: const ['https://cdn.example.com/1.jpg'],
      included: const ['Tastings', 'Water'],
      notIncluded: const ['Transport'],
      locationName: 'Mercado Municipal',
      city: 'São Paulo',
      country: 'Brazil',
      lat: -23.54,
      lng: -46.63,
      geohash: '6gyf4bf',
      meetingPoint: 'Main entrance',
      durationMinutes: 150,
      languages: const ['Portuguese', 'English'],
      minGroupSize: 2,
      maxGroupSize: 8,
      price: 50,
      currency: r'R$',
      paymentLink: const PaymentLink(
          type: PaymentLinkType.pix, value: 'host@example.com'),
      paymentMethods: const {PaymentMethod.cash, PaymentMethod.link},
      availability: 'Saturdays 10:00',
      cancellationPolicy: CancellationPolicy.strict,
      cancellationNotes: 'Free up to 24h before',
      status: ExperienceStatus.published,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000500000),
      ratingSum: 13,
      ratingCount: 3,
      ratingAvg: 4.33,
      ratingDist: const {4: 2, 5: 1},
      reviewCount: 3,
      viewCount: 7,
      searchKeywords: const ['street', 'food', 'walk'],
    );

void main() {
  group('UserExperienceModel', () {
    test('JSON round-trip preserves every field', () {
      final e = _sample();
      final json = UserExperienceModel.toJson(e);
      expect(UserExperienceModel.fromMap(e.id, json), e);
    });

    test('reads Firestore Timestamps and string-keyed rating distribution', () {
      final e = UserExperienceModel.fromMap('x', {
        'hostId': 'h',
        'title': 'Title here',
        'status': 'hidden',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        'ratingDist': {'5': 2, '1': 1, '9': 4},
        'moderation': {'reason': 'prohibited_terms'},
      });
      expect(e.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(e.ratingDist, {5: 2, 1: 1});
      expect(e.status, ExperienceStatus.hidden);
      expect(e.moderationReason, 'prohibited_terms');
    });

    test('unknown enum values fall back safely', () {
      final e = UserExperienceModel.fromMap('x', {
        'category': 'dating',
        'status': 'weird',
        'paymentLink': {'type': 'bitcoin', 'value': 'https://pay.example'},
      });
      expect(e.category, ExperienceCategory.other);
      expect(e.status, ExperienceStatus.draft);
      expect(e.paymentLink?.type, PaymentLinkType.other);
      expect(e.paymentLink?.isOpenable, isTrue);
    });

    test('editable payload never carries server-owned fields', () {
      final p = UserExperienceModel.editablePayload(_sample());
      for (final k in [
        'hostId',
        'status',
        'createdAt',
        'updatedAt',
        'ratingSum',
        'ratingCount',
        'ratingAvg',
        'ratingDist',
        'reviewCount',
        'viewCount',
        'moderation',
      ]) {
        expect(p.containsKey(k), isFalse, reason: k);
      }
      expect(p['searchKeywords'], containsAll(['street', 'food', 'paulo']));
    });

    test('create payload: free experiences drop price/currency; hidden → draft', () {
      final free = UserExperience(
        id: '',
        hostId: 'h',
        title: 'Free walk',
        description: 'x' * 40,
        category: ExperienceCategory.toursWalks,
        mainPhotoUrl: 'https://a/b.jpg',
        included: const ['Guide'],
        locationName: 'Park',
        durationMinutes: 60,
        languages: const ['English'],
        maxGroupSize: 5,
        price: 99,
        currency: '€',
        isFree: true,
        status: ExperienceStatus.hidden,
      );
      final p = UserExperienceModel.createPayload(free);
      expect(p['price'], 0);
      expect(p['currency'], isNull);
      expect(p['status'], 'draft');
    });

    test('legacy free-text cancellation policy reads as moderate + notes', () {
      final e = UserExperienceModel.fromMap('x', {
        'cancellationPolicy': 'Full refund 48h before',
      });
      expect(e.cancellationPolicy, CancellationPolicy.moderate);
      expect(e.cancellationNotes, 'Full refund 48h before');
      final n = UserExperienceModel.fromMap('y', {
        'cancellationPolicy': 'flexible',
        'cancellationNotes': 'Rain = full refund',
      });
      expect(n.cancellationPolicy, CancellationPolicy.flexible);
      expect(n.cancellationNotes, 'Rain = full refund');
      expect(UserExperienceModel.fromMap('z', {}).cancellationPolicy,
          CancellationPolicy.moderate);
    });

    test('PIX keys are copied, URLs opened', () {
      expect(
          const PaymentLink(type: PaymentLinkType.pix, value: '123.456.789-00')
              .isOpenable,
          isFalse);
      expect(
          const PaymentLink(
                  type: PaymentLinkType.paypal, value: 'https://paypal.me/ana')
              .isOpenable,
          isTrue);
    });
  });

  group('ExperienceReviewModel', () {
    test('review JSON round-trip', () {
      final r = ExperienceReview(
        experienceId: 'e',
        authorId: 'u1',
        rating: 4,
        comment: 'Great!',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000100000),
        status: ReviewStatus.rejected,
        moderationReason: 'contains_link',
      );
      expect(
          ExperienceReviewModel.fromMap(
              'e', 'u1', ExperienceReviewModel.toJson(r)),
          r);
      expect(r.isEdited, isTrue);
    });

    test('rating is clamped to 1..5; missing status is pending', () {
      final r = ExperienceReviewModel.fromMap('e', 'u', {'rating': 9});
      expect(r.rating, 5);
      expect(r.status, ReviewStatus.pending);
      expect(r.authorId, 'u');
    });

    test('reply JSON round-trip', () {
      final r = ExperienceReply(
        id: 'r1',
        experienceId: 'e',
        reviewId: 'u1',
        authorId: 'u2',
        text: '@Ana thanks!',
        mentions: const ['u1'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        status: ReviewStatus.visible,
      );
      expect(
          ExperienceReviewModel.replyFromMap(
              'e', 'u1', 'r1', ExperienceReviewModel.replyToJson(r)),
          r);
    });
  });
}
