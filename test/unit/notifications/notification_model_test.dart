import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/notifications/data/models/notification_model.dart';
import 'package:greengo_chat/features/notifications/domain/entities/notification.dart';
import 'package:greengo_chat/features/notifications/presentation/bloc/notifications_state.dart';

import '../../support/notifications_fixtures.dart';

/// Pure model/entity tests for notifications: the type<->wire mapping, the
/// type->icon mapping, and Firestore/JSON round-trips.
void main() {
  group('NotificationType wire mapping', () {
    test('every type round-trips through value -> fromString', () {
      for (final t in NotificationType.values) {
        expect(NotificationTypeExtension.fromString(t.value), t,
            reason: '${t.name} must round-trip');
      }
    });

    test('unknown / garbage strings fall back to system', () {
      expect(NotificationTypeExtension.fromString('nope'),
          NotificationType.system);
      expect(NotificationTypeExtension.fromString(''),
          NotificationType.system);
    });

    test('the event_broadcast alias maps to eventAnnouncement', () {
      expect(NotificationTypeExtension.fromString('event_broadcast'),
          NotificationType.eventAnnouncement);
    });
  });

  group('NotificationEntity.iconName mapping', () {
    test('event-family types share the "event" icon', () {
      for (final t in [
        NotificationType.newEvent,
        NotificationType.communityEvent,
        NotificationType.eventJoin,
        NotificationType.eventReminder,
      ]) {
        expect(NotificationFixtures.build(type: t).iconName, 'event');
      }
    });

    test('group-family types share the "groups" icon', () {
      for (final t in [
        NotificationType.groupMessage,
        NotificationType.groupAdd,
        NotificationType.groupJoin,
      ]) {
        expect(NotificationFixtures.build(type: t).iconName, 'groups');
      }
    });

    test('representative singletons map to the expected icons', () {
      expect(NotificationFixtures.build(type: NotificationType.system).iconName,
          'info');
      expect(
          NotificationFixtures.build(type: NotificationType.newMessage)
              .iconName,
          'chat_bubble');
      expect(
          NotificationFixtures.build(type: NotificationType.coinsPurchased)
              .iconName,
          'monetization_on');
      expect(
          NotificationFixtures.build(type: NotificationType.communityJoin)
              .iconName,
          'campaign');
    });

    test('every type produces a non-empty icon name', () {
      for (final t in NotificationType.values) {
        expect(NotificationFixtures.build(type: t).iconName, isNotEmpty);
      }
    });
  });

  group('NotificationModel Firestore round-trip', () {
    test('toFirestore -> fromFirestore preserves fields', () async {
      final db = FakeFirebaseFirestore();
      final model = NotificationModel(
        notificationId: 'n42',
        userId: 'user_1',
        type: NotificationType.eventJoin,
        title: 'Someone joined',
        message: 'Ava joined your event',
        createdAt: DateTime(2026, 7, 15, 12, 30),
        isRead: true,
        actionUrl: '/events/e1',
        actorId: 'ava',
        actorName: 'Ava',
      );

      await db.collection('notifications').doc('n42').set(model.toFirestore());
      final snap = await db.collection('notifications').doc('n42').get();
      final restored = NotificationModel.fromFirestore(snap);

      expect(restored.notificationId, 'n42');
      expect(restored.userId, 'user_1');
      expect(restored.type, NotificationType.eventJoin);
      expect(restored.title, 'Someone joined');
      expect(restored.message, 'Ava joined your event');
      expect(restored.isRead, isTrue);
      expect(restored.actionUrl, '/events/e1');
      expect(restored.actorId, 'ava');
      expect(restored.actorName, 'Ava');
      expect(restored.createdAt, DateTime(2026, 7, 15, 12, 30));
    });

    test('fromFirestore tolerates a malformed/legacy doc without throwing',
        () async {
      final db = FakeFirebaseFirestore();
      // Missing title/message/type/createdAt (unresolved serverTimestamp etc.).
      await db
          .collection('notifications')
          .doc('legacy')
          .set(<String, dynamic>{'userId': 'user_1'});
      final snap = await db.collection('notifications').doc('legacy').get();

      final restored = NotificationModel.fromFirestore(snap);

      expect(restored.notificationId, 'legacy');
      expect(restored.title, '');
      expect(restored.message, '');
      expect(restored.type, NotificationType.system);
      expect(restored.isRead, isFalse);
    });
  });

  group('NotificationModel JSON round-trip + conversions', () {
    test('toJson -> fromJson preserves the core fields', () {
      final model = NotificationModel(
        notificationId: 'n7',
        userId: 'user_1',
        type: NotificationType.coinsPurchased,
        title: 'Coins added',
        message: '+100 coins',
        createdAt: DateTime(2026, 7, 15, 9),
        isRead: true,
        actionUrl: '/wallet',
        imageUrl: 'https://example.com/x.png',
      );

      final restored = NotificationModel.fromJson(model.toJson());

      expect(restored.notificationId, 'n7');
      expect(restored.type, NotificationType.coinsPurchased);
      expect(restored.title, 'Coins added');
      expect(restored.isRead, isTrue);
      expect(restored.imageUrl, 'https://example.com/x.png');
      expect(restored.createdAt, DateTime(2026, 7, 15, 9));
    });

    test('toEntity produces an equal NotificationEntity', () {
      final model = NotificationModel(
        notificationId: 'n8',
        userId: 'user_1',
        type: NotificationType.system,
        title: 'Hi',
        message: 'There',
        createdAt: DateTime(2026, 7, 15),
      );

      expect(model.toEntity(), isA<NotificationEntity>());
      expect(model.toEntity().notificationId, 'n8');
    });
  });

  group('NotificationEntity helpers', () {
    test('copyWith flips isRead without touching other fields', () {
      final n = NotificationFixtures.build(id: 'n1', isRead: false);

      final read = n.copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.notificationId, 'n1');
      expect(read.title, n.title);
    });

    test('timeSinceText returns "Just now" for a fresh notification', () {
      final n = NotificationFixtures.build(createdAt: DateTime.now());
      expect(n.timeSinceText, 'Just now');
    });
  });

  group('NotificationsLoaded.actualUnreadCount', () {
    test('counts only unread notifications', () {
      final state = NotificationsLoaded(
        notifications: NotificationFixtures.mixed(), // 2 unread + 1 read
      );
      expect(state.actualUnreadCount, 2);
    });

    test('is zero when everything is read', () {
      final state = NotificationsLoaded(
        notifications: [
          NotificationFixtures.build(id: 'a', isRead: true),
          NotificationFixtures.build(id: 'b', isRead: true),
        ],
      );
      expect(state.actualUnreadCount, 0);
    });
  });
}
