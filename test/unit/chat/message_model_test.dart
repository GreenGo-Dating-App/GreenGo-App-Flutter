import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/data/models/message_model.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';

import '../../support/chat_fixtures.dart';

/// Master Test Plan — Chat/Messaging. MessageType/MessageStatus wire mapping and
/// MessageModel Firestore round-trips (read flags + sentAt).
void main() {
  group('MessageType wire mapping', () {
    test('value() emits the exact wire strings', () {
      expect(MessageType.text.value, 'text');
      expect(MessageType.image.value, 'image');
      expect(MessageType.video.value, 'video');
      expect(MessageType.gif.value, 'gif');
      expect(MessageType.voiceNote.value, 'voice_note');
      expect(MessageType.sticker.value, 'sticker');
      expect(MessageType.system.value, 'system');
      expect(MessageType.albumShare.value, 'album_share');
      expect(MessageType.albumRevoke.value, 'album_revoke');
      expect(MessageType.location.value, 'location');
      expect(MessageType.event.value, 'event');
    });

    test('fromString round-trips every known type', () {
      for (final t in MessageType.values) {
        expect(MessageTypeExtension.fromString(t.value), t);
      }
    });

    test('fromString falls back to text for garbage', () {
      expect(MessageTypeExtension.fromString('nope'), MessageType.text);
      expect(MessageTypeExtension.fromString(''), MessageType.text);
    });
  });

  group('MessageStatus wire mapping', () {
    test('value() round-trips every status', () {
      for (final s in MessageStatus.values) {
        expect(MessageStatusExtension.fromString(s.value), s);
      }
    });

    test('fromString falls back to sent for unknown', () {
      expect(MessageStatusExtension.fromString('bogus'), MessageStatus.sent);
    });
  });

  group('MessageModel.toFirestore', () {
    test('encodes type.value, status.value and sentAt as Timestamp', () {
      final model = MessageModel.fromEntity(
        ChatFixtures.message(
          type: MessageType.image,
          status: MessageStatus.delivered,
          content: 'photo',
        ),
      );

      final map = model.toFirestore();

      expect(map['type'], 'image');
      expect(map['status'], 'delivered');
      expect(map['content'], 'photo');
      expect(map['sentAt'], isA<Timestamp>());
      expect(map['readAt'], isNull);
    });

    test('encodes read flags (readAt) when present', () {
      final model = MessageModel.fromEntity(
        ChatFixtures.message(
          readAt: DateTime(2026, 7, 15, 15),
          status: MessageStatus.read,
        ),
      );

      final map = model.toFirestore();

      expect(map['readAt'], isA<Timestamp>());
      expect(map['status'], 'read');
    });

    test('encodes readBy per-member map as Timestamps', () {
      final model = MessageModel.fromEntity(
        ChatFixtures.message(readBy: {'b': DateTime(2026, 7, 15, 16)}),
      );

      final readBy = model.toFirestore()['readBy'] as Map;

      expect(readBy['b'], isA<Timestamp>());
    });
  });

  group('MessageModel.fromFirestore', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('round-trips content/type/sentAt through Firestore', () async {
      final model = MessageModel.fromEntity(
        ChatFixtures.message(
          messageId: 'm_rt',
          type: MessageType.sticker,
          content: 'sparkle',
        ),
      );
      await db.collection('messages').doc('m_rt').set(model.toFirestore());

      final snap = await db.collection('messages').doc('m_rt').get();
      final parsed = MessageModel.fromFirestore(snap);

      expect(parsed.messageId, 'm_rt');
      expect(parsed.type, MessageType.sticker);
      expect(parsed.content, 'sparkle');
      expect(parsed.sentAt, DateTime(2026, 7, 15, 12));
    });

    test('unread message: readAt null → isRead false', () async {
      final model = MessageModel.fromEntity(ChatFixtures.message());
      await db.collection('messages').doc('m_unread').set(model.toFirestore());

      final snap = await db.collection('messages').doc('m_unread').get();
      final parsed = MessageModel.fromFirestore(snap);

      expect(parsed.isRead, isFalse);
      expect(parsed.readAt, isNull);
    });
  });

  group('Message read/sender helpers', () {
    test('isSentBy matches the sender only', () {
      final m = ChatFixtures.message(senderId: 'ava', receiverId: 'elena');
      expect(m.isSentBy('ava'), isTrue);
      expect(m.isSentBy('elena'), isFalse);
    });

    test('isReadBy uses readBy map for groups, readAt fallback for 1:1', () {
      final group = ChatFixtures.message(readBy: {'b': DateTime(2026, 7, 15)});
      expect(group.isReadBy('b'), isTrue);
      expect(group.isReadBy('c'), isFalse);

      final oneToOne = ChatFixtures.message(readAt: DateTime(2026, 7, 15));
      expect(oneToOne.isReadBy('anyone'), isTrue);
      expect(ChatFixtures.message().isReadBy('anyone'), isFalse);
    });

    test('readByCount counts group readers, falls back to 1:1 readAt', () {
      expect(
        ChatFixtures.message(readBy: {'b': DateTime(2026, 7, 15)}).readByCount,
        1,
      );
      expect(
        ChatFixtures.message(readAt: DateTime(2026, 7, 15)).readByCount,
        1,
      );
      expect(ChatFixtures.message().readByCount, 0);
    });
  });
}
