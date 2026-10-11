import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/deep_link_service.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  group('DeepLinkService link building', () {
    test('profile / event / community links use the share host', () {
      expect(DeepLinkService.buildProfileLink('uid123'),
          'https://greengo-chat.web.app/u/uid123');
      expect(DeepLinkService.buildEventLink('ev_1'),
          'https://greengo-chat.web.app/e/ev_1');
      expect(DeepLinkService.buildCommunityLink('c-1'),
          'https://greengo-chat.web.app/c/c-1');
      expect(DeepLinkService.buildExperienceLink('exp_1'),
          'https://greengo-chat.web.app/x/exp_1');
      expect(DeepLinkService.buildAttractionLink(4242),
          'https://greengo-chat.web.app/a/4242');
    });

    test('experience / attraction links parse back to their targets', () {
      expect(
          DeepLinkService.parse(
              Uri.parse(DeepLinkService.buildExperienceLink('exp_1'))),
          const DeepLinkTarget(DeepLinkKind.experience, 'exp_1'));
      expect(
          DeepLinkService.parse(
              Uri.parse(DeepLinkService.buildAttractionLink(4242))),
          const DeepLinkTarget(DeepLinkKind.attraction, '4242'));
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
      expect(p('https://greengo-chat.web.app/x/exp1'),
          const DeepLinkTarget(DeepLinkKind.experience, 'exp1'));
      expect(p('greengo://x/exp1'),
          const DeepLinkTarget(DeepLinkKind.experience, 'exp1'));
      expect(p('https://greengo-chat.web.app/a/4242'),
          const DeepLinkTarget(DeepLinkKind.attraction, '4242'));
      expect(p('greengo://a/4242'),
          const DeepLinkTarget(DeepLinkKind.attraction, '4242'));
    });

    test('attraction ids must be numeric', () {
      expect(p('https://greengo-chat.web.app/a/colosseum'), isNull);
      expect(p('greengo://a/abc'), isNull);
    });

    test('web hand-off query from the share page (desktop browsers)', () {
      expect(p('https://greengo-chat.web.app/?link=%2Fu%2Fabc'),
          const DeepLinkTarget(DeepLinkKind.profile, 'abc'));
      expect(p('https://greengo-chat.web.app/?link=%2Fu%2Fabc#/'),
          const DeepLinkTarget(DeepLinkKind.profile, 'abc'));
      expect(p('https://greengo-chat.web.app/?link=%2Fx%2Fexp1'),
          const DeepLinkTarget(DeepLinkKind.experience, 'exp1'));
      expect(p('https://greengo-chat.web.app/?link=%2Fa%2F4242'),
          const DeepLinkTarget(DeepLinkKind.attraction, '4242'));
    });

    test('rejects foreign hosts, unknown kinds and malformed ids', () {
      expect(p('https://evil.example.com/u/abc'), isNull);
      expect(p('https://greengo-chat.web.app/z/abc'), isNull);
      expect(p('https://greengo-chat.web.app/x/a%3Cb'), isNull);
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
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('own profile invites to chat', () {
      expect(
          profileShareText(
              link: link, isSelf: true, displayName: 'Ana', l10n: l10n),
          l10n.shareProfileMessage(link));
    });

    test("someone else's profile names them", () {
      expect(
          profileShareText(
              link: link, isSelf: false, displayName: 'Ana', l10n: l10n),
          l10n.shareOtherProfileMessage('Ana', link));
    });

    test('no name falls back to the generic text', () {
      expect(
          profileShareText(
              link: link, isSelf: false, displayName: '  ', l10n: l10n),
          l10n.shareProfileMessage(link));
    });
  });

  group('share texts are localized (no English fallbacks)', () {
    test('experience / attraction / community / event texts carry the link',
        () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        const x = 'https://greengo-chat.web.app/x/exp_1';
        const a = 'https://greengo-chat.web.app/a/4242';
        expect(experienceShareText(link: x, title: 'Pasta', l10n: l10n),
            l10n.uexpShareText('Pasta', x));
        expect(attractionShareText(link: a, name: ' Colosseum ', l10n: l10n),
            l10n.shareAttractionMessage('Colosseum', a));
        expect(attractionShareText(link: a, name: 'Colosseum', l10n: l10n),
            contains(a));
        expect(
            communityShareText(
                link: 'L', name: 'Club', l10n: l10n),
            l10n.shareCommunityMessage('Club', 'L'));
        expect(eventShareText(link: 'L', l10n: l10n, title: ''),
            l10n.shareEventMessage('L'));
      }
    });
  });
}
