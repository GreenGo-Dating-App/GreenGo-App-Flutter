import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/keyword_matcher.dart';
import 'package:greengo_chat/features/chat/domain/chat_places.dart';

ChatPlaceSource _msg(String id, String text, int minute, {bool partner = true, List<Map<String, Object>>? entities}) => (
      id: id,
      text: text,
      metadata: entities == null ? null : {'entities': entities},
      sentAt: DateTime(2026, 10, 13, 10, minute),
      fromPartner: partner,
    );

void main() {
  final messages = [
    _msg('m1', 'I loved Rome last year', 1, entities: [
      {'s': 8, 'e': 12, 'k': 'c', 'r': ['IT:rome']},
    ]),
    _msg('m2', 'Did you see the Colosseo?', 2, partner: false, entities: [
      {'s': 16, 'e': 24, 'k': 'a', 'r': ['401']},
    ]),
    _msg('m3', 'Yes! Rome and Portugal are my favourites', 3, entities: [
      {'s': 5, 'e': 9, 'k': 'c', 'r': ['IT:rome']},
      {'s': 14, 'e': 22, 'k': 'k', 'r': ['PT']},
    ]),
  ];

  test('collect: each place once, newest mention first, label as written', () {
    final places = ChatPlaces.collect(messages);
    expect(places.map((p) => p.key), ['c:IT:rome', 'k:PT', 'a:401']);
    expect(places.first.messageId, 'm3');
    expect(places[2].label, 'Colosseo');
    expect(places[2].fromPartner, isFalse);
    expect(places.first.iso2, 'IT');
    expect(places[1].iso2, 'PT');
    expect(places[2].attractionIds, [401]);
  });

  test('latestFromPartner: places of the newest partner message among the last ones', () {
    final places = ChatPlaces.collect(messages);
    expect(ChatPlaces.latestFromPartner(places, messages).map((p) => p.key), ['c:IT:rome', 'k:PT']);
    // An older partner mention outside the window gives no suggestions.
    final later = [
      ...messages,
      _msg('m4', 'ok', 4, partner: false),
      _msg('m5', 'see you', 5, partner: false),
      _msg('m6', 'bye', 6, partner: false),
    ];
    expect(ChatPlaces.latestFromPartner(ChatPlaces.collect(later), later), isEmpty);
  });

  test('stored entities that do not fit the text are ignored', () {
    final bad = [
      _msg('x', 'short', 1, entities: [
        {'s': 0, 'e': 50, 'k': 'c', 'r': ['IT:rome']},
      ]),
    ];
    expect(ChatPlaces.collect(bad), isEmpty);
    expect(KeywordKind.fromCode('c'), KeywordKind.city);
  });
}
