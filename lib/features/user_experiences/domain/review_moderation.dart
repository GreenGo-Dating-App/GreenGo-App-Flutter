import '../../../core/services/content_filter_service.dart';

/// Client-side verdict on review / reply text, before it is submitted.
/// The server re-checks with the same rules (functions/src/user_experiences/
/// moderation.ts) because the client can be bypassed.
enum CommentVerdict { ok, empty, tooLong, prohibited, containsLink }

class ReviewModeration {
  const ReviewModeration._();

  static final RegExp _link = RegExp(r'(https?://|\bwww\.)', caseSensitive: false);

  static bool containsLink(String text) => _link.hasMatch(text);

  /// Decision for [text] with a [maxLength] limit. [allowEmpty] for reviews,
  /// where the stars alone are a valid review.
  static CommentVerdict check(
    String text, {
    required int maxLength,
    bool allowEmpty = false,
  }) {
    final t = text.trim();
    if (t.isEmpty) return allowEmpty ? CommentVerdict.ok : CommentVerdict.empty;
    if (t.length > maxLength) return CommentVerdict.tooLong;
    if (ContentFilterService().findProhibitedTerms(t).isNotEmpty) {
      return CommentVerdict.prohibited;
    }
    if (containsLink(t)) return CommentVerdict.containsLink;
    return CommentVerdict.ok;
  }
}
