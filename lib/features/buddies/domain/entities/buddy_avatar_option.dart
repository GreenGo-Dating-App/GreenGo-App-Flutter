import 'package:equatable/equatable.dart';

/// One picture a Buddy can wear: a document of `buddy_avatars/{id}`
/// ({url, thumbUrl?, label, order, active}); the images live in our Storage.
/// Owner 2026-10-25: a 512 px [url] + a 192 px [thumbUrl] (WebP).
/// [id] is what a Buddy stores in `settings.avatar`.
class BuddyAvatarOption extends Equatable {
  const BuddyAvatarOption({
    required this.id,
    required this.url,
    this.thumbUrl,
    this.label = '',
    this.order = 0,
    this.active = true,
  });

  final String id;

  /// https download URL of the image.
  final String url;

  /// https URL of the small (192 px) thumbnail, when the picture has one.
  final String? thumbUrl;
  final String label;
  final int order;

  /// Offered in the picker. Retired pictures stay resolvable so the Buddies
  /// that wear them keep showing them.
  final bool active;

  /// Thumbnail edge: pictures decoded up to this many pixels use [thumbUrl].
  static const int thumbPx = 192;

  /// Parses one `buddy_avatars` document; null when it can not be shown
  /// (no https URL, bad id).
  static BuddyAvatarOption? fromMap(String id, Map<String, dynamic> d) {
    final url = d['url'];
    if (!_id.hasMatch(id) || url is! String || !_https(url)) return null;
    final thumb = d['thumbUrl'];
    final label = d['label'];
    final order = d['order'];
    return BuddyAvatarOption(
      id: id,
      url: url,
      thumbUrl: thumb is String && _https(thumb) ? thumb : null,
      label: label is String ? label.trim() : '',
      order: order is num ? order.toInt() : 0,
      active: d['active'] != false,
    );
  }

  static bool _https(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  /// Same rule as the server (`AVATAR_ID` in functions/src/buddies/model.ts).
  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  @override
  List<Object?> get props => [id, url, thumbUrl, label, order, active];
}
