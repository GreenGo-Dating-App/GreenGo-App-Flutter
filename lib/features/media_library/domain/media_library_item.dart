import 'package:cloud_firestore/cloud_firestore.dart';

/// One picture in "My pictures" (`media_library/{uid}/items/{id}`).
///
/// Written only by the server when a moderation verdict lands
/// (functions/src/safety/mediaLibrary.ts); the app reads and removes entries.
/// Only [isApproved] items have a [url] and can be reused anywhere.
class MediaLibraryItem {
  const MediaLibraryItem({
    required this.id,
    required this.path,
    required this.status,
    this.url,
    this.thumbUrl,
    this.width,
    this.height,
    this.hasFace,
    this.usage,
    this.reasons = const [],
    this.reviewable = false,
    this.reviewStatus,
    this.createdAt,
    this.approvedAt,
  });

  factory MediaLibraryItem.fromMap(String id, Map<String, dynamic> d) {
    final review = d['review'];
    return MediaLibraryItem(
      id: id,
      path: (d['path'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'held',
      url: d['url'] as String?,
      thumbUrl: d['thumbUrl'] as String?,
      width: (d['width'] as num?)?.toInt(),
      height: (d['height'] as num?)?.toInt(),
      hasFace: d['hasFace'] as bool?,
      usage: d['usage'] as String?,
      reasons: (d['reasons'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      reviewable: d['reviewable'] == true,
      reviewStatus: review is Map ? review['status'] as String? : null,
      createdAt: _date(d['createdAt']),
      approvedAt: _date(d['approvedAt']),
    );
  }

  final String id;
  final String path;

  /// `approved`, `held` (automatic hold) or `rejected` (a person decided).
  final String status;
  final String? url;
  final String? thumbUrl;
  final int? width;
  final int? height;
  final bool? hasFace;
  final String? usage;
  final List<String> reasons;
  final bool reviewable;

  /// Review request: `pending`, `approved`, `rejected`, or null (none).
  final String? reviewStatus;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  bool get isApproved => status == 'approved' && (url ?? '').isNotEmpty;
  bool get isReviewPending => reviewStatus == 'pending';

  /// The owner may tap "Ask for a review".
  bool get canAskForReview =>
      !isApproved && reviewable && !isReviewPending;

  /// Grid thumbnail: the stored thumb, else the image itself.
  String? get displayUrl => (thumbUrl ?? '').isNotEmpty ? thumbUrl : url;

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}

/// One page of library items plus the cursor for the next page.
class MediaLibraryPage {
  const MediaLibraryPage(this.items, this.cursor, {required this.hasMore});

  final List<MediaLibraryItem> items;

  /// Opaque cursor (a DocumentSnapshot in production); null on the last page.
  final Object? cursor;
  final bool hasMore;
}
