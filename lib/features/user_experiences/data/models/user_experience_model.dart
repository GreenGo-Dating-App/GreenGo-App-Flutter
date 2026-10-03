import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/experience_review.dart';
import '../../domain/entities/user_experience.dart';
import '../../domain/experience_validation.dart';

/// Firestore value (Timestamp / DateTime / millis / ISO string) → DateTime.
DateTime? experienceDateFrom(Object? v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

String? _optStr(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

List<String> _strList(Object? v) =>
    v is List ? v.whereType<String>().toList(growable: false) : const [];

int _int(Object? v, [int fallback = 0]) =>
    v is num ? v.toInt() : fallback;

int? _optInt(Object? v) => v is num ? v.toInt() : null;

double? _optDouble(Object? v) => v is num ? v.toDouble() : null;

/// (De)serialisation of [UserExperience] — `user_experiences/{id}`.
class UserExperienceModel {
  const UserExperienceModel._();

  static UserExperience fromMap(String id, Map<String, dynamic> d) {
    final pl = d['paymentLink'];
    final distRaw = d['ratingDist'];
    final dist = <int, int>{};
    if (distRaw is Map) {
      for (final e in distRaw.entries) {
        final star = int.tryParse('${e.key}');
        if (star != null && star >= 1 && star <= 5 && e.value is num) {
          dist[star] = (e.value as num).toInt();
        }
      }
    }
    final mod = d['moderation'];
    final link = pl is Map && _optStr(pl['value']) != null
        ? PaymentLink(
            type: PaymentLinkType.fromWire(pl['type']),
            value: _optStr(pl['value'])!,
          )
        : null;
    final isFree = d['isFree'] == true;
    final rawMethods = d['paymentMethods'];
    final methods = <PaymentMethod>{
      if (rawMethods is List)
        for (final m in rawMethods)
          if (PaymentMethod.tryWire(m) != null) PaymentMethod.tryWire(m)!,
    };
    // Legacy docs (before payment methods): a link means "link".
    if (rawMethods is! List && !isFree && link != null) {
      methods.add(PaymentMethod.link);
    }
    // Fixed policy, or (legacy docs) free text → moderate + that text as notes.
    final policy = CancellationPolicy.tryWire(d['cancellationPolicy']);
    final notes = _optStr(d['cancellationNotes']) ??
        (policy == null ? _optStr(d['cancellationPolicy']) : null);
    return UserExperience(
      id: id,
      hostId: d['hostId'] as String? ?? '',
      hostName: _optStr(d['hostName']),
      hostPhotoUrl: _optStr(d['hostPhotoUrl']),
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      category: ExperienceCategory.fromWire(d['category']),
      mainPhotoUrl: d['mainPhotoUrl'] as String? ?? '',
      photoUrls: _strList(d['photoUrls']),
      included: _strList(d['included']),
      notIncluded: _strList(d['notIncluded']),
      locationName: d['locationName'] as String? ?? '',
      city: _optStr(d['city']),
      country: _optStr(d['country']),
      lat: _optDouble(d['lat']),
      lng: _optDouble(d['lng']),
      geohash: _optStr(d['geohash']),
      meetingPoint: _optStr(d['meetingPoint']),
      durationMinutes: _int(d['durationMinutes']),
      languages: _strList(d['languages']),
      minGroupSize: _optInt(d['minGroupSize']),
      maxGroupSize: _int(d['maxGroupSize'], 1),
      price: _optDouble(d['price']) ?? 0,
      currency: _optStr(d['currency']),
      isFree: isFree,
      paymentLink: link,
      paymentMethods: isFree ? const {} : methods,
      availability: _optStr(d['availability']),
      cancellationPolicy: policy ?? CancellationPolicy.fallback,
      cancellationNotes: notes,
      // Request to book is mandatory for every experience.
      requestToBook: true,
      status: ExperienceStatus.fromWire(d['status']),
      createdAt: experienceDateFrom(d['createdAt']),
      updatedAt: experienceDateFrom(d['updatedAt']),
      ratingSum: _int(d['ratingSum']),
      ratingCount: _int(d['ratingCount']),
      ratingAvg: _optDouble(d['ratingAvg']) ?? 0,
      ratingDist: dist,
      reviewCount: _int(d['reviewCount']),
      viewCount: _int(d['viewCount']),
      searchKeywords: _strList(d['searchKeywords']),
      moderationReason: mod is Map ? _optStr(mod['reason']) : null,
      // Server-owned (read-only here; never in editablePayload/createPayload).
      isFeatured: d['isFeatured'] == true,
      featuredUntil: experienceDateFrom(d['featuredUntil']),
      // Server-owned community link (createUserExperience only).
      communityId: _optStr(d['communityId']),
      communityName: _optStr(d['communityName']),
    );
  }

  static UserExperience fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      fromMap(doc.id, doc.data() ?? const {});

  /// The CLIENT-writable fields (what create/update send). Never contains
  /// hostId, status 'hidden', timestamps or any rating aggregate.
  static Map<String, dynamic> editablePayload(UserExperience e) {
    final included = ExperienceValidator.cleanItems(e.included);
    final notIncluded = ExperienceValidator.cleanItems(e.notIncluded);
    return {
      'title': e.title.trim(),
      'description': e.description.trim(),
      'category': e.category.name,
      'mainPhotoUrl': e.mainPhotoUrl,
      'photoUrls': e.photoUrls,
      'included': included,
      'notIncluded': notIncluded,
      'locationName': e.locationName.trim(),
      'city': e.city,
      'country': e.country,
      'lat': e.lat,
      'lng': e.lng,
      'geohash': e.geohash,
      'meetingPoint': e.meetingPoint,
      'durationMinutes': e.durationMinutes,
      'languages': e.languages,
      'minGroupSize': e.minGroupSize,
      'maxGroupSize': e.maxGroupSize,
      'price': e.isFree ? 0 : e.price,
      'currency': e.isFree ? null : e.currency,
      'isFree': e.isFree,
      // Free: no methods, no link. Paid: the chosen methods; the link only
      // when 'link' is one of them.
      'paymentMethods': e.isFree
          ? const <String>[]
          : [
              for (final m in PaymentMethod.values)
                if (e.paymentMethods.contains(m)) m.name,
            ],
      'paymentLink': e.isFree ||
              e.paymentLink == null ||
              !e.paymentMethods.contains(PaymentMethod.link)
          ? null
          : {'type': e.paymentLink!.type.name, 'value': e.paymentLink!.value},
      'availability': e.availability,
      'cancellationPolicy': e.cancellationPolicy.name,
      'cancellationNotes': e.cancellationNotes,
      'requestToBook': e.requestToBook,
      'searchKeywords': buildExperienceKeywords(
          [e.title, e.city, e.country, e.category.name, e.locationName]),
    };
  }

  /// Payload of the `createUserExperience` callable (JSON-safe). The
  /// community link is requested here only (the server checks the host may
  /// post there and stores the community name itself); edits never send it.
  static Map<String, dynamic> createPayload(UserExperience e) => {
        ...editablePayload(e),
        'status': e.status == ExperienceStatus.published
            ? 'published'
            : 'draft',
        'hostName': e.hostName,
        'hostPhotoUrl': e.hostPhotoUrl,
        if (e.isInCommunity) 'communityId': e.communityId,
      };

  /// Full JSON (dates as epoch millis) — local caching / round-trip tests.
  static Map<String, dynamic> toJson(UserExperience e) => {
        ...editablePayload(e),
        'hostId': e.hostId,
        'hostName': e.hostName,
        'hostPhotoUrl': e.hostPhotoUrl,
        'status': e.status.name,
        'createdAt': e.createdAt?.millisecondsSinceEpoch,
        'updatedAt': e.updatedAt?.millisecondsSinceEpoch,
        'ratingSum': e.ratingSum,
        'ratingCount': e.ratingCount,
        'ratingAvg': e.ratingAvg,
        'ratingDist': {
          for (final en in e.ratingDist.entries) '${en.key}': en.value,
        },
        'reviewCount': e.reviewCount,
        'viewCount': e.viewCount,
        'searchKeywords': e.searchKeywords,
        if (e.moderationReason != null)
          'moderation': {'reason': e.moderationReason},
        'isFeatured': e.isFeatured,
        'featuredUntil': e.featuredUntil?.millisecondsSinceEpoch,
        if (e.communityId != null) 'communityId': e.communityId,
        if (e.communityName != null) 'communityName': e.communityName,
      };
}

/// (De)serialisation of reviews and replies.
class ExperienceReviewModel {
  const ExperienceReviewModel._();

  static ExperienceReview fromMap(
      String experienceId, String id, Map<String, dynamic> d) {
    final mod = d['moderation'];
    return ExperienceReview(
      experienceId: experienceId,
      authorId: d['authorId'] as String? ?? id,
      rating: _int(d['rating'], 1).clamp(1, 5),
      comment: d['comment'] as String? ?? '',
      createdAt: experienceDateFrom(d['createdAt']),
      updatedAt: experienceDateFrom(d['updatedAt']),
      status: ReviewStatus.fromWire(d['status']),
      moderationReason: mod is Map ? _optStr(mod['reason']) : null,
    );
  }

  static Map<String, dynamic> toJson(ExperienceReview r) => {
        'authorId': r.authorId,
        'rating': r.rating,
        'comment': r.comment,
        'createdAt': r.createdAt?.millisecondsSinceEpoch,
        'updatedAt': r.updatedAt?.millisecondsSinceEpoch,
        'status': r.status.name,
        if (r.moderationReason != null)
          'moderation': {'reason': r.moderationReason},
      };

  static ExperienceReply replyFromMap(String experienceId, String reviewId,
          String id, Map<String, dynamic> d) =>
      ExperienceReply(
        id: id,
        experienceId: experienceId,
        reviewId: reviewId,
        authorId: d['authorId'] as String? ?? '',
        text: d['text'] as String? ?? '',
        mentions: _strList(d['mentions']),
        createdAt: experienceDateFrom(d['createdAt']),
        status: ReviewStatus.fromWire(d['status']),
      );

  static Map<String, dynamic> replyToJson(ExperienceReply r) => {
        'authorId': r.authorId,
        'text': r.text,
        'mentions': r.mentions,
        'createdAt': r.createdAt?.millisecondsSinceEpoch,
        'status': r.status.name,
      };
}
