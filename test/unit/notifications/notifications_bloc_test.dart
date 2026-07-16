import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/notifications/domain/entities/notification.dart';
import 'package:greengo_chat/features/notifications/domain/repositories/notification_repository.dart';
import 'package:greengo_chat/features/notifications/domain/usecases/get_notifications.dart';
import 'package:greengo_chat/features/notifications/domain/usecases/mark_all_notifications_read.dart';
import 'package:greengo_chat/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:greengo_chat/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:greengo_chat/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:greengo_chat/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/notifications_fixtures.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

/// NotificationsBloc — REGRESSION coverage for the optimistic clear-all /
/// clear-unread flows. The bloc resolves the repository via GetIt
/// (di.sl<NotificationRepository>()), so the mock is registered in GetIt.I.
void main() {
  late MockNotificationRepository repo;
  late NotificationsBloc bloc;

  NotificationsBloc buildBloc() => NotificationsBloc(
        getNotifications: GetNotifications(repo),
        markNotificationRead: MarkNotificationRead(repo),
        markAllNotificationsRead: MarkAllNotificationsRead(repo),
      );

  setUp(() {
    repo = MockNotificationRepository();
    // The bloc calls di.sl<NotificationRepository>() for the delete flows.
    GetIt.I.registerFactory<NotificationRepository>(() => repo);
    bloc = buildBloc();
  });

  tearDown(() async {
    await bloc.close();
    await GetIt.I.reset();
  });

  void stubLoad(List<NotificationEntity> list) {
    when(() => repo.getNotificationsStream(
          any(),
          unreadOnly: any(named: 'unreadOnly'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) => Stream.value(Right(list)));
  }

  group('load', () {
    test('emits [Loading, Loaded] with the correct unread count', () async {
      stubLoad(NotificationFixtures.mixed());

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotificationsLoading>(),
          isA<NotificationsLoaded>()
              .having((s) => s.notifications.length, 'length', 3)
              .having((s) => s.unreadCount, 'unreadCount', 2),
        ]),
      );

      bloc.add(const NotificationsLoadRequested(userId: 'user_1'));
      await expectation;
    });

    test('emits [Loading, Empty] when there are no notifications', () async {
      stubLoad(const []);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotificationsLoading>(),
          isA<NotificationsEmpty>(),
        ]),
      );

      bloc.add(const NotificationsLoadRequested(userId: 'user_1'));
      await expectation;
    });

    test('emits [Loading, Error] when the stream yields a Failure', () async {
      when(() => repo.getNotificationsStream(
            any(),
            unreadOnly: any(named: 'unreadOnly'),
            limit: any(named: 'limit'),
          )).thenAnswer(
          (_) => Stream.value(const Left(ServerFailure('boom'))));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotificationsLoading>(),
          isA<NotificationsError>(),
        ]),
      );

      bloc.add(const NotificationsLoadRequested(userId: 'user_1'));
      await expectation;
    });
  });

  group('NotificationsAllCleared (optimistic delete-all)', () {
    test('emits NotificationsEmpty IMMEDIATELY before the server delete',
        () async {
      when(() => repo.deleteAll(any()))
          .thenAnswer((_) async => const Right(null));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<NotificationsEmpty>()]),
      );

      bloc.add(const NotificationsAllCleared('user_1'));
      await expectation;
    });

    test('clears even when a populated list is currently loaded', () async {
      stubLoad(NotificationFixtures.mixed());
      when(() => repo.deleteAll(any()))
          .thenAnswer((_) async => const Right(null));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotificationsLoading>(),
          isA<NotificationsLoaded>(),
          isA<NotificationsEmpty>(),
        ]),
      );

      bloc.add(const NotificationsLoadRequested(userId: 'user_1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NotificationsAllCleared('user_1'));
      await expectation;
    });

    test('calls repository.deleteAll with the user id', () async {
      when(() => repo.deleteAll(any()))
          .thenAnswer((_) async => const Right(null));

      bloc.add(const NotificationsAllCleared('user_1'));
      await untilCalled(() => repo.deleteAll(any()));

      verify(() => repo.deleteAll('user_1')).called(1);
    });
  });

  group('NotificationsUnreadCleared (optimistic drop-unread)', () {
    test('drops the unread ones, keeping only read notifications', () async {
      stubLoad(NotificationFixtures.mixed()); // 2 unread + 1 read
      when(() => repo.deleteAllUnread(any()))
          .thenAnswer((_) async => const Right(null));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotificationsLoading>(),
          isA<NotificationsLoaded>(),
          isA<NotificationsLoaded>()
              .having((s) => s.notifications.length, 'length', 1)
              .having((s) => s.notifications.every((n) => n.isRead),
                  'all read', isTrue),
        ]),
      );

      bloc.add(const NotificationsLoadRequested(userId: 'user_1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NotificationsUnreadCleared('user_1'));
      await expectation;
    });

    test('emits NotificationsEmpty when every notification was unread',
        () async {
      stubLoad(NotificationFixtures.allUnread());
      when(() => repo.deleteAllUnread(any()))
          .thenAnswer((_) async => const Right(null));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotificationsLoading>(),
          isA<NotificationsLoaded>(),
          isA<NotificationsEmpty>(),
        ]),
      );

      bloc.add(const NotificationsLoadRequested(userId: 'user_1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NotificationsUnreadCleared('user_1'));
      await expectation;
    });

    test('still calls deleteAllUnread on the server', () async {
      stubLoad(NotificationFixtures.mixed());
      when(() => repo.deleteAllUnread(any()))
          .thenAnswer((_) async => const Right(null));

      bloc.add(const NotificationsLoadRequested(userId: 'user_1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NotificationsUnreadCleared('user_1'));
      await untilCalled(() => repo.deleteAllUnread(any()));

      verify(() => repo.deleteAllUnread('user_1')).called(1);
    });
  });

  group('single-item actions delegate to the repository', () {
    test('NotificationDeleted deletes via the repository', () async {
      when(() => repo.deleteNotification(any()))
          .thenAnswer((_) async => const Right(null));

      bloc.add(const NotificationDeleted('n1'));
      await untilCalled(() => repo.deleteNotification(any()));

      verify(() => repo.deleteNotification('n1')).called(1);
    });

    test('NotificationMarkedAsRead marks it read', () async {
      when(() => repo.markAsRead(any()))
          .thenAnswer((_) async => const Right(null));

      bloc.add(const NotificationMarkedAsRead('n1'));
      await untilCalled(() => repo.markAsRead(any()));

      verify(() => repo.markAsRead('n1')).called(1);
    });

    test('NotificationsMarkedAllAsRead marks all read', () async {
      when(() => repo.markAllAsRead(any()))
          .thenAnswer((_) async => const Right(null));

      bloc.add(const NotificationsMarkedAllAsRead('user_1'));
      await untilCalled(() => repo.markAllAsRead(any()));

      verify(() => repo.markAllAsRead('user_1')).called(1);
    });

    test('NotificationTapped marks the tapped notification read', () async {
      when(() => repo.markAsRead(any()))
          .thenAnswer((_) async => const Right(null));

      bloc.add(const NotificationTapped(notificationId: 'n1'));
      await untilCalled(() => repo.markAsRead(any()));

      verify(() => repo.markAsRead('n1')).called(1);
    });
  });
}
