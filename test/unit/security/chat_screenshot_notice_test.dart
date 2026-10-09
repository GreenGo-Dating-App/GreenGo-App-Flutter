import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/data/services/chat_screenshot_notice.dart';
import 'package:greengo_chat/features/chat/domain/chat_system_message.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/presentation/utils/chat_l10n.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// "X took a screenshot" system line in 1:1 and group chats.
void main() {
  late FakeFirebaseFirestore fs;
  late DateTime now;
  late ChatScreenshotNotice notice;

  setUp(() {
    fs = FakeFirebaseFirestore();
    now = DateTime(2026, 10, 9, 12);
    notice = ChatScreenshotNotice(firestore: fs, clock: () => now);
  });

  test('1:1: writes a system line as the screenshotter', () async {
    final ok = await notice.postToConversation(
      conversationId: 'c1',
      senderId: 'me',
      receiverId: 'you',
      senderName: 'Mia',
    );
    expect(ok, isTrue);
    final docs = (await fs.collection('conversations/c1/messages').get()).docs;
    expect(docs, hasLength(1));
    final d = docs.single.data();
    expect(d['senderId'], 'me');
    expect(d['receiverId'], 'you');
    expect(d['type'], 'system');
    expect(d['content'], 'Mia took a screenshot');
    expect(d['metadata'], {
      'systemKey': ChatSystemKey.screenshotTaken,
      'systemParams': {'name': 'Mia'},
    });
  });

  test('group: writes to groups/{id}/messages', () async {
    expect(
        await notice.postToGroup(groupId: 'g1', senderId: 'me', senderName: ''),
        isTrue);
    final d =
        (await fs.collection('groups/g1/messages').get()).docs.single.data();
    expect(d['senderId'], 'me');
    expect(d['type'], 'system');
    expect(d['content'], 'Someone took a screenshot');
    expect((d['metadata'] as Map)['systemKey'], ChatSystemKey.screenshotTaken);
  });

  test('throttled per chat', () async {
    Future<bool> post(String id) => notice.postToConversation(
        conversationId: id, senderId: 'me', receiverId: 'you', senderName: 'M');
    expect(await post('c1'), isTrue);
    expect(await post('c1'), isFalse); // burst
    expect(await post('c2'), isTrue); // other chat unaffected
    now = now.add(const Duration(seconds: 31));
    expect(await post('c1'), isTrue);
    expect((await fs.collection('conversations/c1/messages').get()).docs,
        hasLength(2));
  });

  test('missing ids write nothing', () async {
    expect(
        await notice.postToConversation(
            conversationId: '', senderId: 'me', receiverId: 'x', senderName: ''),
        isFalse);
    expect(await notice.postToGroup(groupId: 'g', senderId: '', senderName: ''),
        isFalse);
  });

  test('rendered in the reader language', () {
    final msg = Message(
      messageId: 'm',
      matchId: 'c1',
      conversationId: 'c1',
      senderId: 'me',
      receiverId: 'you',
      content: ChatScreenshotNotice.fallbackContent('Mia'),
      type: MessageType.system,
      sentAt: DateTime(2026),
      metadata:
          chatSystemMetadata(ChatSystemKey.screenshotTaken, {'name': 'Mia'}),
    );
    const expected = <String, String>{
      'en': 'Mia took a screenshot',
      'de': 'Mia hat einen Screenshot gemacht',
      'es': 'Mia hizo una captura de pantalla',
      'fr': "Mia a fait une capture d'écran",
      'it': 'Mia ha fatto uno screenshot',
      'pt': 'Mia fez uma captura de ecrã',
    };
    expected.forEach((lang, text) {
      expect(chatMessageDisplayText(lookupAppLocalizations(Locale(lang)), msg),
          text,
          reason: lang);
    });
    expect(
        chatMessageDisplayText(
            lookupAppLocalizations(const Locale('pt', 'BR')), msg),
        'Mia fez uma captura de tela');
  });
}
