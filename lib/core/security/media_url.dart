/// Cache key that survives URL re-signing.
///
/// Private album photos are served as short-lived V4 signed URLs
/// (`getSharedAlbum`), whose query string changes on every fetch. Keyed by
/// the full URL, the image cache would re-download every time; keyed by the
/// object (`gs://bucket/path`), the token / download-URL and every signed URL
/// of the same object share one cache entry. Anything else: the URL itself.
String stableMediaCacheKey(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return url;
  try {
    // https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token=
    final fb = RegExp(r'^/v0/b/([^/]+)/o/(.+)$').firstMatch(uri.path);
    if (fb != null) {
      return 'gs://${fb.group(1)}/${Uri.decodeComponent(fb.group(2)!)}';
    }
    // https://storage.googleapis.com/{bucket}/{path}?X-Goog-Signature=
    if (uri.host == 'storage.googleapis.com' && uri.pathSegments.length > 1) {
      final bucket = uri.pathSegments.first;
      final path = uri.pathSegments.skip(1).join('/');
      return 'gs://$bucket/$path';
    }
    // https://{bucket}.storage.googleapis.com/{path}?X-Goog-Signature=
    const suffix = '.storage.googleapis.com';
    if (uri.host.endsWith(suffix) && uri.pathSegments.isNotEmpty) {
      final bucket = uri.host.substring(0, uri.host.length - suffix.length);
      return 'gs://$bucket/${uri.pathSegments.join('/')}';
    }
  } catch (_) {
    // Malformed escapes: fall through to the raw URL.
  }
  return url;
}
