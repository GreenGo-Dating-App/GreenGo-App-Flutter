import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/keyword_matcher.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';
import 'package:greengo_chat/features/buddies/presentation/buddy_chat_adapter.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/domain/message_insights.dart';

void main() {
  final index = KeywordIndex.fromJson({
    'a': <String, dynamic>{},
    'c': {'IT:rome': ['Rome'], 'FR:nice': ['Nice']},
    'k': {'IT': 'Italy'},
    'n': [
      ['rome', 'c', 'IT:rome', 0],
      ['italy', 'k', 'IT', 0],
      // A common word: only matched when written with a capital letter.
      ['nice', 'c', 'FR:nice', 1],
    ],
  });
  final at = DateTime(2026, 10, 24);

  BuddyMessage buddy(String text, {List<BuddyKeyword> keywords = const []}) => BuddyMessage(
      id: 'm1', role: BuddyMessageRole.buddy, text: text, createdAt: at, keywords: keywords);

  test('Buddy message -> chat text message, never a CEFR level', () {
    final m = BuddyChatAdapter.toMessage(buddy('Rome in spring'),
        uid: 'u1', buddyId: 'b1', buddyLanguage: 'it', translated: 'Roma', index: index);
    expect(m.type, MessageType.text);
    expect(m.senderId, 'buddy:b1');
    expect(m.receiverId, 'u1');
    expect(m.conversationId, isEmpty, reason: 'not a conversations doc');
    expect(m.translatedContent, 'Roma');
    expect(m.detectedLanguage, 'it');
    expect(m.metadata!['language'], 'it');
    expect(m.metadata!.containsKey('level'), isFalse);
    expect(MessageInsights.storedLevel(m.metadata), isNull);
    expect(MessageInsights.storedEntities(m.metadata, m.content)!.single.refs, ['IT:rome']);
  });

  test('user messages: delivery state -> message status', () {
    final sending = BuddyMessage(
        id: 'local_1',
        role: BuddyMessageRole.user,
        text: 'hi',
        createdAt: at,
        delivery: BuddyDelivery.sending);
    expect(
        BuddyChatAdapter.toMessage(sending, uid: 'u1', buddyId: 'b1', buddyLanguage: 'en').status,
        MessageStatus.sending);
    final stored = BuddyMessage(id: 's1', role: BuddyMessageRole.user, text: 'hi', createdAt: at);
    final m = BuddyChatAdapter.toMessage(stored, uid: 'u1', buddyId: 'b1', buddyLanguage: 'en');
    expect(m.senderId, 'u1');
    expect(m.isRead, isTrue);
    expect(m.metadata!.containsKey('language'), isFalse);
  });

  test('server keywords add places the matcher missed (resolved through the index)', () {
    final plain = BuddyChatAdapter.keywordMatches('so nice and Italy', const [], index)!;
    expect(plain.map((k) => k.refs.first), ['IT'], reason: 'lower-case "nice" is a common word');
    final withServer = BuddyChatAdapter.keywordMatches('so nice and Italy',
        const [BuddyKeyword(type: 'city', name: 'Nice')], index)!;
    expect(withServer.map((k) => k.refs.first), ['FR:nice', 'IT']);
    // Unknown to the index: no target, so not tappable (skipped).
    expect(
        BuddyChatAdapter.keywordMatches(
            'Atlantis', const [BuddyKeyword(type: 'city', name: 'Atlantis')], index),
        isEmpty);
    expect(BuddyChatAdapter.keywordMatches('Rome', const [], null), isNull,
        reason: 'index loading: the bubble matches by itself');
  });

  test('a translation into another language is never shown (old English cache in an Italian chat)', () {
    final m = BuddyMessage(id: 'm2', role: BuddyMessageRole.buddy, text: 'Hi, how are you?', createdAt: at,
        translation: const BuddyTranslation(text: 'Hi there, how are you doing?', lang: 'en'));
    expect(BuddyChatAdapter.shownTranslation(m, chatLanguage: 'it', buddyLanguage: 'de'), isNull);
    final it = BuddyMessage(id: 'm3', role: BuddyMessageRole.buddy, text: 'Hallo, wie geht es dir?', createdAt: at,
        translation: const BuddyTranslation(text: 'Ciao, come stai?', lang: 'it'));
    expect(BuddyChatAdapter.shownTranslation(it, chatLanguage: 'it', buddyLanguage: 'de'), 'Ciao, come stai?');
    expect(BuddyChatAdapter.shownTranslation(it, chatLanguage: 'it', buddyLanguage: 'it'), isNull);
  });
}
