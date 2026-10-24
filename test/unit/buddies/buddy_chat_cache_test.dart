import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/data/datasources/buddy_chat_cache.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';

BuddyMessage msg(String id, int minute, {String? translation, bool buddy = true}) => BuddyMessage(
      id: id,
      role: buddy ? BuddyMessageRole.buddy : BuddyMessageRole.user,
      text: 'text $id',
      createdAt: DateTime(2026, 10, 24, 9).add(Duration(minutes: minute)),
      translation: translation == null ? null : BuddyTranslation(text: translation, lang: 'it'),
    );

void main() {
  late MemoryBuddyChatCacheStore store;
  late JsonBuddyChatCache cache;

  setUp(() {
    store = MemoryBuddyChatCacheStore();
    cache = JsonBuddyChatCache(store: store);
  });

  test('round trip keeps text, role, kind, keywords and the stored translation', () async {
    final m = BuddyMessage(
      id: 'm1',
      role: BuddyMessageRole.buddy,
      text: 'Have you seen Lisbon?',
      kind: BuddyMessageKind.checkin,
      charged: 'free',
      createdAt: DateTime(2026, 10, 24, 9),
      keywords: const [BuddyKeyword(type: 'city', name: 'Lisbon')],
      translation: const BuddyTranslation(text: 'Hai visto Lisbona?', lang: 'it'),
    );
    await cache.save('b1', [m, msg('u1', 1, buddy: false, translation: 'Ciao')]);
    final back = await cache.load('b1');
    expect(back, [m, msg('u1', 1, buddy: false, translation: 'Ciao')]);
    expect(back.first.translation, const BuddyTranslation(text: 'Hai visto Lisbona?', lang: 'it'));
  });

  test('local (unsent) messages are never cached', () async {
    await cache.save('b1', [
      msg('s1', 0),
      BuddyMessage(
          id: 'local_x',
          role: BuddyMessageRole.user,
          text: 'pending',
          createdAt: DateTime(2026, 10, 24, 9, 1),
          delivery: BuddyDelivery.sending),
    ]);
    expect((await cache.load('b1')).map((m) => m.id), ['s1']);
  });

  test('bounded: the newest 50 messages per Buddy, the 10 most recent Buddies', () async {
    await cache.save('b0', [for (var i = 0; i < 80; i++) msg('m$i', i)]);
    final kept = await cache.load('b0');
    expect(kept.length, JsonBuddyChatCache.maxMessages);
    expect(kept.first.id, 'm30');
    expect(kept.last.id, 'm79');

    for (var b = 1; b <= 10; b++) {
      await cache.save('b$b', [msg('x', 0)]);
    }
    // b0 was the least recently used: dropped; the 10 others stay.
    expect(await cache.load('b0'), isEmpty);
    for (var b = 1; b <= 10; b++) {
      expect(await cache.load('b$b'), isNotEmpty, reason: 'b$b');
    }
    expect(store.values[JsonBuddyChatCache.indexKey], hasLength(JsonBuddyChatCache.maxBuddies));
  });

  test('clear removes one Buddy chat only', () async {
    await cache.save('b1', [msg('a', 0)]);
    await cache.save('b2', [msg('b', 0)]);
    await cache.clear('b1');
    expect(await cache.load('b1'), isEmpty);
    expect(await cache.load('b2'), isNotEmpty);
    expect(store.values[JsonBuddyChatCache.indexKey], ['b2']);
  });

  test('junk in the store is ignored', () async {
    store.values[JsonBuddyChatCache.keyOf('b1')] = [
      'x',
      {'id': '', 'text': 't', 'at': 1},
      {'id': 'ok', 'text': 'fine', 'at': 1000, 'translation': {'text': 'bene'}},
    ];
    final list = await cache.load('b1');
    expect(list.single.id, 'ok');
    expect(list.single.translation?.text, 'bene');
  });
}
