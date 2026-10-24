import 'package:equatable/equatable.dart';

/// One picture a Buddy can wear: a document of `buddy_avatars/{id}`
/// ({url, label, order, active}); the image lives in our Storage.
/// [id] is what a Buddy stores in `settings.avatar`.
class BuddyAvatarOption extends Equatable {
  const BuddyAvatarOption({
    required this.id,
    required this.url,
    this.label = '',
    this.order = 0,
  });

  final String id;

  /// https download URL of the image.
  final String url;
  final String label;
  final int order;

  /// Parses one `buddy_avatars` document; null when it can not be shown
  /// (no https URL, bad id).
  static BuddyAvatarOption? fromMap(String id, Map<String, dynamic> d) {
    final url = d['url'];
    if (!_id.hasMatch(id) || url is! String) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    final label = d['label'];
    final order = d['order'];
    return BuddyAvatarOption(
      id: id,
      url: url,
      label: label is String ? label.trim() : '',
      order: order is num ? order.toInt() : 0,
    );
  }

  /// Same rule as the server (`AVATAR_ID` in functions/src/buddies/model.ts).
  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  @override
  List<Object?> get props => [id, url, label, order];
}
