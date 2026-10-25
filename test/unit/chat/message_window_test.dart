import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/domain/entities/message_page.dart';
import 'package:greengo_chat/features/chat/domain/message_window.dart';

final _t0 = DateTime(2026, 10, 24, 9);

/// Message `m<i>` sent [i] minutes after 9:00 (higher = newer).
Message msg(int i, {String content = ''}) => Message(
  messageId: 'm$i',
  matchId: 'match1',
  conversationId: 'c1',
  senderId: 'a',
  receiverId: 'b',
  content: content.isEmpty ? 'text $i' : content,
  type: MessageType.text,
  sentAt: _t0.add(Duration(minutes: i)),
);

/// A page holding messages [from]..[to] (inclusive), newest first, as the
/// datasource returns it: full when it holds [limit] messages.
MessagePage page(
  int from,
  int to, {
  int limit = 20,
  bool fromCache = false,
  Set<int> hidden = const {},
}) {
  final read = [for (var i = to; i >= from; i--) i];
  return MessagePage(
    messages: [
      for (final i in read)
        if (!hidden.contains(i)) msg(i),
    ],
    hasMore: read.length >= limit,
    cursor: read.isEmpty ? null : msg(read.last).sentAt,
    fromCache: fromCache,
  );
}

List<String> ids(MessageWindow w) => [for (final m in w.messages) m.messageId];

void main() {
  late MessageWindow w;
  setUp(() => w = MessageWindow());

  test('cache first: the cached copy shows before any live snapshot', () {
    expect(w.showCached([msg(1), msg(3), msg(2)]), isTrue);
    expect(ids(w), ['m3', 'm2', 'm1']);
    expect(w.showingCache, isTrue);
    expect(w.liveLoaded, isFalse);
    // Older pages wait for the live window (it knows whether there are any).
    expect(w.hasMore, isFalse);
  });

  test(
    'an empty answer of the local Firestore cache keeps the cached copy',
    () {
      w.showCached([msg(1), msg(2)]);
      expect(w.applyLive(page(0, -1, fromCache: true)), isFalse);
      expect(ids(w), ['m2', 'm1']);
      // The server's (empty) answer is the truth.
      expect(w.applyLive(page(0, -1)), isTrue);
      expect(w.messages, isEmpty);
    },
  );

  test('the live window replaces the cache; overlap keeps the older cached '
      'messages without duplicates', () {
    // Cached: m10..m59 (newest 50). Live: the newest 20 = m45..m64.
    w.showCached([for (var i = 10; i <= 59; i++) msg(i)]);
    w.applyLive(page(45, 64));
    expect(w.messages.length, 55); // m10..m64, each once
    expect(ids(w).toSet().length, w.messages.length);
    expect(w.messages.first.messageId, 'm64');
    expect(w.messages.last.messageId, 'm10');
    // The next older page starts after the oldest kept cached message.
    expect(w.nextCursor, msg(10).sentAt);
    expect(w.hasMore, isTrue);
  });

  test('a gap since the cache was saved drops the cached messages', () {
    // Cached m0..m9; 40 messages arrived since: the live window m30..m49
    // does not overlap the cache.
    w.showCached([for (var i = 0; i <= 9; i++) msg(i)]);
    w.applyLive(page(30, 49));
    expect(ids(w), [for (var i = 49; i >= 30; i--) 'm$i']);
    expect(w.nextCursor, msg(30).sentAt);
  });

  test('a window that is not full holds the whole history', () {
    w.applyLive(page(1, 5));
    expect(w.hasMore, isFalse);
    expect(w.messages.length, 5);
  });

  test('older page on scroll: cursor-based, appended, no duplicates', () {
    w.applyLive(page(40, 59));
    expect(w.nextCursor, msg(40).sentAt);
    // The server returns an overlapping page (m35..m41 overlap is harmless).
    w.applyOlder(page(21, 41));
    expect(ids(w).toSet().length, w.messages.length);
    expect(w.messages.length, 39); // m21..m59
    expect(w.nextCursor, msg(21).sentAt);
    expect(w.hasMore, isTrue);

    // Last page: not full → history complete.
    w.applyOlder(page(15, 20));
    expect(w.messages.last.messageId, 'm15');
    expect(w.hasMore, isFalse);
  });

  test('an older page of hidden (deleted-for-me) messages still advances '
      'the cursor', () {
    w.applyLive(page(40, 59));
    w.applyOlder(page(20, 39, hidden: {for (var i = 20; i <= 39; i++) i}));
    expect(w.messages.length, 20);
    expect(w.nextCursor, msg(20).sentAt);
    expect(w.hasMore, isTrue);
  });

  test('a new message pushes the oldest out of the window into the older '
      'pages (it stays on screen)', () {
    w.applyLive(page(40, 59));
    w.applyLive(page(41, 60));
    expect(ids(w).first, 'm60');
    expect(ids(w), contains('m40'));
    expect(w.messages.length, 21);
    // The next page starts after the window (re-reading m40 is harmless).
    expect(w.nextCursor, msg(41).sentAt);
  });

  test('a message deleted inside the window disappears', () {
    w.applyLive(page(1, 10));
    w.applyLive(page(1, 10, hidden: {5}));
    expect(ids(w), isNot(contains('m5')));
    expect(w.messages.length, 9);
  });

  test('an edited message in the window replaces its older-page copy', () {
    w.applyLive(page(40, 59));
    w.applyOlder(page(20, 39));
    final edited = MessagePage(
      messages: [for (var i = 59; i >= 40; i--) msg(i, content: 'v2 $i')],
      hasMore: true,
      cursor: msg(40).sentAt,
    );
    w.applyLive(edited);
    expect(
      w.messages.where((m) => m.messageId == 'm45').single.content,
      'v2 45',
    );
    expect(w.messages.length, 40);
  });

  test('drop removes a message from the older pages', () {
    w.applyLive(page(40, 59));
    w.applyOlder(page(20, 39));
    expect(w.drop('m25'), isTrue);
    expect(ids(w), isNot(contains('m25')));
    expect(w.drop('nope'), isFalse);
  });
}
