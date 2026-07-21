import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/profile/domain/entities/social_links.dart';

/// Master Test Plan — Profile / social links entity.
/// Covers the data behind E2E matrix items #70 (launch social link from
/// profile) and #280 (edit social links). Pure tests against the real
/// [SocialLinks] entity: presence flags, count, and URL normalization.
void main() {
  group('presence flags', () {
    test('empty() has no links', () {
      const s = SocialLinks.empty();
      expect(s.hasAnyLink, isFalse);
      expect(s.linkedCount, 0);
    });

    test('hasAnyLink true when any non-empty field is set', () {
      expect(const SocialLinks(instagram: 'ava').hasAnyLink, isTrue);
    });

    test('empty-string fields do not count as links', () {
      const s = SocialLinks(facebook: '', instagram: '');
      expect(s.hasAnyLink, isFalse);
      expect(s.linkedCount, 0);
    });

    test('linkedCount counts every populated platform', () {
      const s = SocialLinks(
        facebook: 'fb',
        instagram: 'ig',
        tiktok: 'tt',
        linkedin: 'li',
        x: 'xh',
      );
      expect(s.linkedCount, 5);
    });
  });

  group('URL normalization', () {
    test('instagram/tiktok/x strip a leading @ and build handle URLs', () {
      const s = SocialLinks(instagram: '@ava', tiktok: '@dex', x: '@zoe');
      expect(s.instagramUrl, 'https://www.instagram.com/ava');
      expect(s.tiktokUrl, 'https://www.tiktok.com/@dex');
      expect(s.xUrl, 'https://www.x.com/zoe');
    });

    test('facebook passes an absolute http(s) value through unchanged', () {
      const s = SocialLinks(facebook: 'https://facebook.com/ava.reyes');
      expect(s.facebookUrl, 'https://facebook.com/ava.reyes');
    });

    test('facebook wraps a bare handle into a profile URL', () {
      const s = SocialLinks(facebook: 'ava.reyes');
      expect(s.facebookUrl, 'https://www.facebook.com/ava.reyes');
    });

    test('linkedin passes an absolute URL through, wraps a bare handle', () {
      expect(const SocialLinks(linkedin: 'http://linkedin.com/in/ava').linkedinUrl,
          'http://linkedin.com/in/ava');
      expect(const SocialLinks(linkedin: 'ava').linkedinUrl,
          'https://www.linkedin.com/in/ava');
    });

    test('URL getters are null when the field is null or empty', () {
      const s = SocialLinks.empty();
      expect(s.facebookUrl, isNull);
      expect(s.instagramUrl, isNull);
      expect(s.tiktokUrl, isNull);
      expect(s.linkedinUrl, isNull);
      expect(s.xUrl, isNull);
      expect(const SocialLinks(instagram: '').instagramUrl, isNull);
    });
  });

  group('copyWith & equality', () {
    test('copyWith overrides only the given field', () {
      const original = SocialLinks(instagram: 'ava', tiktok: 'dex');
      final updated = original.copyWith(instagram: 'ava2');
      expect(updated.instagram, 'ava2');
      expect(updated.tiktok, 'dex');
    });

    test('value equality holds for identical field sets', () {
      expect(const SocialLinks(instagram: 'ava'),
          const SocialLinks(instagram: 'ava'));
    });
  });
}
