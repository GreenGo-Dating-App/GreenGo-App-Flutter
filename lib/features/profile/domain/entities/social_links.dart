import 'package:equatable/equatable.dart';

/// Social Links Entity
/// Represents user's social media profile links
class SocialLinks extends Equatable {
  /// Facebook profile URL or username
  final String? facebook;

  /// Instagram username (without @)
  final String? instagram;

  /// TikTok username (without @)
  final String? tiktok;

  /// LinkedIn profile URL or username
  final String? linkedin;

  /// X (Twitter) username (without @)
  final String? x;

  const SocialLinks({
    this.facebook,
    this.instagram,
    this.tiktok,
    this.linkedin,
    this.x,
  });

  /// Create empty social links
  const SocialLinks.empty()
      : facebook = null,
        instagram = null,
        tiktok = null,
        linkedin = null,
        x = null;

  /// Check if any social link is set
  bool get hasAnyLink =>
      facebook != null ||
      instagram != null ||
      tiktok != null ||
      linkedin != null ||
      x != null;

  /// Get the count of linked social profiles
  int get linkedCount {
    int count = 0;
    if (facebook != null && facebook!.isNotEmpty) count++;
    if (instagram != null && instagram!.isNotEmpty) count++;
    if (tiktok != null && tiktok!.isNotEmpty) count++;
    if (linkedin != null && linkedin!.isNotEmpty) count++;
    if (x != null && x!.isNotEmpty) count++;
    return count;
  }

  /// Get full Facebook URL
  String? get facebookUrl {
    if (facebook == null || facebook!.isEmpty) return null;
    if (facebook!.startsWith('http')) return facebook;
    return 'https://facebook.com/$facebook';
  }

  /// Get full Instagram URL
  String? get instagramUrl {
    if (instagram == null || instagram!.isEmpty) return null;
    final username = instagram!.replaceAll('@', '');
    return 'https://instagram.com/$username';
  }

  /// Get full TikTok URL
  String? get tiktokUrl {
    if (tiktok == null || tiktok!.isEmpty) return null;
    final username = tiktok!.replaceAll('@', '');
    return 'https://tiktok.com/@$username';
  }

  /// Get full LinkedIn URL
  String? get linkedinUrl {
    if (linkedin == null || linkedin!.isEmpty) return null;
    if (linkedin!.startsWith('http')) return linkedin;
    return 'https://linkedin.com/in/$linkedin';
  }

  /// Get full X (Twitter) URL
  String? get xUrl {
    if (x == null || x!.isEmpty) return null;
    final username = x!.replaceAll('@', '');
    return 'https://x.com/$username';
  }

  /// Create a copy with updated values
  SocialLinks copyWith({
    String? facebook,
    String? instagram,
    String? tiktok,
    String? linkedin,
    String? x,
  }) {
    return SocialLinks(
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      linkedin: linkedin ?? this.linkedin,
      x: x ?? this.x,
    );
  }

  @override
  List<Object?> get props => [facebook, instagram, tiktok, linkedin, x];
}
