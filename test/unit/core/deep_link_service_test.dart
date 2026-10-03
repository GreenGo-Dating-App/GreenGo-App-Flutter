import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/deep_link_service.dart';

void main() {
  group('DeepLinkService link building', () {
    test('profile / event / community links use the share host', () {
      expect(DeepLinkService.buildProfileLink('uid123'),
          'https://greengo-chat.web.app/u/uid123');
      expect(DeepLinkService.buildEventLink('ev_1'),
          'https://greengo-chat.web.app/e/ev_1');
      expect(DeepLinkService.buildCommunityLink('c-1'),
          'https://greengo-chat.web.app/c/c-1');
    });

    test('ids are trimmed and URL-encoded', () {
      expect(DeepLinkService.buildProfileLink(' a b/c '),
          'https://greengo-chat.web.app/u/a%20b%2Fc');
    });

    test('a built link parses back to the same target', () {
      final link = Uri.parse(DeepLinkService.buildProfileLink('uid123'));
      expect(DeepLinkService.parse(link),
          const DeepLinkTarget(DeepLinkKind.profile, 'uid123'));
    });
  });

  group('DeepLinkService.parse', () {
    DeepLinkTarget? p(String s) => DeepLinkService.parse(Uri.parse(s));

    test('universal links and the custom scheme', () {
      expect(p('https://greengo-chat.web.app/u/abc'),
          const DeepLinkTarget(DeepLinkKind.profile, 'abc'));
      expect(p('https://greengo-chat.web.app/e/ev1'),
          const DeepLinkTarget(DeepLinkKind.event, 'ev1'));
      expect(p('https://greengo-chat.web.app/c/c1'),
          const DeepLinkTarget(DeepLinkKind.community, 'c1'));
      expect(p('greengo://u/abc'),
          const DeepLinkTarget(DeepLinkKind.profile, 'abc'));
    });

    test('web hand-off query from the share page (desktop browsers)', () {
      expect(p('https://greengo-chat.web.app/?link=%2Fu%2Fabc'),
          const DeepLinkTarget(DeepLinkKind.profile, 'abc'));
      expect(p('https://greengo-chat.web.app/?link=%2Fu%2Fabc#/'),
          const DeepLinkTarget(DeepLinkKind.profile, 'abc'));
    });

    test('rejects foreign hosts, unknown kinds and malformed ids', () {
      expect(p('https://evil.example.com/u/abc'), isNull);
      expect(p('https://greengo-chat.web.app/x/abc'), isNull);
      expect(p('https://greengo-chat.web.app/'), isNull);
      expect(p('https://greengo-chat.web.app/u/a%3Cb'), isNull);
      expect(p('https://greengo-chat.web.app/?link=https%3A%2F%2Fevil.com'),
          isNull);
      expect(p('otherapp://u/abc'), isNull);
    });
  });

  group('captureWebLaunchLink', () {
    test('keeps the hand-off target pending for after sign-in', () {
      final s = DeepLinkService.instance;
      s.captureWebLaunchLink(
          Uri.parse('https://greengo-chat.web.app/?link=%2Fu%2Fuid9'));
      expect(s.pendingTarget,
          const DeepLinkTarget(DeepLinkKind.profile, 'uid9'));
    });
  });

  group('profileShareText', () {
    const link = 'https://greengo-chat.web.app/u/uid123';

    test('own profile invites to chat', () {
      expect(profileShareText(link: link, isSelf: true, displayName: 'Ana'),
          'Chat with me on GreenGo: $link');
    });

    test("someone else's profile names them", () {
      expect(profileShareText(link: link, isSelf: false, displayName: 'Ana'),
          'Meet Ana on GreenGo: $link');
    });

    test('no name falls back to the generic text', () {
      expect(profileShareText(link: link, isSelf: false, displayName: '  '),
          'Chat with me on GreenGo: $link');
    });
  });
}
