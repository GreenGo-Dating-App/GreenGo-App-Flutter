import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/server_text.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Server-written notification / system texts stored as ARB key + params
/// (functions/src/shared/i18n) render in the VIEWER's language.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final it = lookupAppLocalizations(const Locale('it'));
  final ptBr = lookupAppLocalizations(const Locale('pt', 'BR'));

  test('plain keys', () {
    expect(serverText(it, 'notifServerTicketReady'), it.notifServerTicketReady);
    expect(serverText(en, 'srvNewEvent'), 'New event');
  });

  test('params, including ints stored as strings or numbers', () {
    expect(serverText(it, 'notifServerJoinedYourEvent', {'name': 'Jazz'}),
        it.notifServerJoinedYourEvent('Jazz'));
    expect(serverText(en, 'srvGroupMembersLeft', {'count': 1}),
        'A member left the group');
    expect(serverText(en, 'srvGroupMembersLeft', {'count': '3'}),
        '3 members left the group');
    expect(serverText(ptBr, 'srvMembershipExpiringBody', {'tier': 'Gold', 'days': 2}),
        ptBr.srvMembershipExpiringBody('Gold', 2));
  });

  test('select on stable ids', () {
    expect(
        serverText(en, 'srvAchievementUnlockedTitle', {'achievement': 'popular'}),
        'Achievement Unlocked: Popular!');
  });

  test('unknown / missing keys return null so callers fall back to stored text', () {
    expect(serverText(en, null), isNull);
    expect(serverText(en, ''), isNull);
    expect(serverText(en, 'keyFromANewerServer'), isNull);
  });

  test('missing params never throw', () {
    expect(serverText(en, 'notifServerNewEventIn'), 'New event in ');
    expect(serverText(en, 'srvPaymentsWaitingCount'), '0 payments');
  });
}
