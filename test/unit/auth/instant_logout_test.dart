import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/services/presence_service.dart';
import 'package:greengo_chat/core/services/sign_out_coordinator.dart';
import 'package:greengo_chat/core/services/sign_out_steps.dart';
import 'package:greengo_chat/features/authentication/domain/entities/user.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_event.dart';
import 'package:greengo_chat/features/authentication/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/auth_fixtures.dart';

/// Instant logout: the UI flips to signed-out immediately while the old
/// user's activities and the Firebase sign-out finish in the background.
void main() {
  late MockAuthRepository repository;
  late MockAccessControlService access;
  late SignOutCoordinator coordinator;
  late StreamController<User?> authStream;
  final user = buildTestUser(id: 'old_uid');

  setUp(() {
    repository = MockAuthRepository();
    access = MockAccessControlService();
    coordinator = SignOutCoordinator(
      stepTimeout: const Duration(milliseconds: 200),
      signOutTimeout: const Duration(seconds: 5),
    );
    authStream = StreamController<User?>.broadcast();
    when(() => repository.authStateChanges).thenAnswer((_) => authStream.stream);
    when(() => repository.getCurrentUser())
        .thenAnswer((_) async => Right(user));
    when(() => access.refreshUserAccessDate(any(), any()))
        .thenAnswer((_) async {});
  });

  tearDown(() => authStream.close());

  Future<AuthBloc> signedInBloc() async {
    final bloc = AuthBloc(
      repository: repository,
      accessControlService: access,
      signOutCoordinator: coordinator,
    );
    bloc.add(const AuthCheckRequested());
    await expectLater(bloc.stream, emits(isA<AuthAuthenticated>()));
    return bloc;
  }

  test('emits AuthUnauthenticated before signOut completes', () async {
    final signOut = Completer<Either<Failure, void>>();
    when(() => repository.signOut()).thenAnswer((_) => signOut.future);

    final bloc = await signedInBloc();
    bloc.add(const AuthSignOutRequested());
    await expectLater(bloc.stream, emits(isA<AuthUnauthenticated>()));

    expect(signOut.isCompleted, isFalse);
    expect(bloc.pendingSignOut, isNotNull);
    expect(coordinator.signingOutUid, 'old_uid');

    signOut.complete(const Right(null));
    await coordinator.waitForPendingSignOut();
    expect(bloc.pendingSignOut, isNull);
    await bloc.close();
  });

  test('a new sign-in waits for the pending sign-out', () async {
    final signOut = Completer<Either<Failure, void>>();
    final order = <String>[];
    when(() => repository.signOut()).thenAnswer((_) async {
      final r = await signOut.future;
      order.add('signOut');
      return r;
    });
    final newUser = buildTestUser(id: 'new_uid');
    when(() => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {
      order.add('signIn');
      return Right(newUser);
    });

    final bloc = await signedInBloc();
    bloc.add(const AuthSignOutRequested());
    await expectLater(bloc.stream, emits(isA<AuthUnauthenticated>()));

    bloc.add(const AuthSignInWithEmailRequested(
        email: 'new@greengo.app', password: 'pw123456'));
    await expectLater(bloc.stream, emits(isA<AuthLoading>()));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(order, isEmpty, reason: 'sign-in must wait for the old sign-out');

    signOut.complete(const Right(null));
    await expectLater(
      bloc.stream,
      emits(isA<AuthAuthenticated>()
          .having((s) => s.user.uid, 'uid', 'new_uid')),
    );
    expect(order, ['signOut', 'signIn']);
    await bloc.close();
  });

  test('background sign-out errors never emit AuthError; signOut retried once',
      () async {
    var calls = 0;
    when(() => repository.signOut()).thenAnswer((_) async {
      calls++;
      return const Left(AuthenticationFailure('boom'));
    });
    coordinator.register(SignOutPhase.presence, 'presence.offline',
        (_) async => throw StateError('presence failed'));

    final bloc = await signedInBloc();
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const AuthSignOutRequested());
    await Future<void>.delayed(Duration.zero);
    await coordinator.waitForPendingSignOut();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(states.whereType<AuthError>(), isEmpty);
    expect(states.last, isA<AuthUnauthenticated>());
    expect(calls, 2, reason: 'signOut is retried once');
    await sub.cancel();
    await bloc.close();
  });

  test('stale "still signed in" events for the old uid are ignored', () async {
    final signOut = Completer<Either<Failure, void>>();
    when(() => repository.signOut()).thenAnswer((_) => signOut.future);

    final bloc = await signedInBloc();
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const AuthSignOutRequested());
    await Future<void>.delayed(Duration.zero);

    authStream.add(user); // Firebase still reports the old user
    bloc.add(const AuthCheckAccessStatusRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(states.whereType<AuthAuthenticated>(), isEmpty);
    expect(bloc.state, isA<AuthUnauthenticated>());

    signOut.complete(const Right(null));
    await coordinator.waitForPendingSignOut();
    await sub.cancel();
    await bloc.close();
  });

  group('SignOutCoordinator', () {
    test('runs every phase in order, then the auth sign-out', () async {
      final log = <String>[];
      coordinator
        ..register(SignOutPhase.localData, 'local', (_) async => log.add('local'))
        ..register(SignOutPhase.listeners, 'listeners',
            (_) async => log.add('listeners'))
        ..register(SignOutPhase.media, 'media', (_) async => log.add('media'))
        ..register(SignOutPhase.push, 'push', (_) async => log.add('push'))
        ..register(SignOutPhase.presence, 'presence',
            (uid) async => log.add('presence:$uid'));

      await coordinator.start(
          uid: 'u1', finalSignOut: () async => log.add('auth'));
      expect(log, [
        'listeners',
        'presence:u1',
        'push',
        'media',
        'local',
        'auth',
      ]);
      expect(coordinator.lastResults.every((r) => r.ok), isTrue);
    });

    test('a hanging or failing step never blocks the others', () async {
      final log = <String>[];
      coordinator
        ..register(SignOutPhase.listeners, 'hangs',
            (_) => Completer<void>().future)
        ..register(SignOutPhase.presence, 'throws',
            (_) async => throw Exception('x'))
        ..register(SignOutPhase.localData, 'local', (_) async => log.add('local'));

      await coordinator.start(
          uid: 'u1', finalSignOut: () async => log.add('auth'));
      expect(log, ['local', 'auth']);
      final failed = coordinator.lastResults.where((r) => !r.ok).map((r) => r.name);
      expect(failed, containsAll(['hangs', 'throws']));
    });

    test('concurrent start() joins the running job', () async {
      var runs = 0;
      final gate = Completer<void>();
      Future<void> signOut() async {
        runs++;
        await gate.future;
      }

      final a = coordinator.start(uid: 'u1', finalSignOut: signOut);
      final b = coordinator.start(uid: 'u1', finalSignOut: signOut);
      expect(identical(a, b), isTrue);
      gate.complete();
      await a;
      expect(runs, 1);
      expect(coordinator.isSigningOut, isFalse);
    });
  });

  group('ends every activity of the old user', () {
    test('after logout no listener/timer for the old uid stays active and '
        'its caches are empty', () async {
      // A fake "session" of the old user: two live snapshot-style listeners,
      // a periodic timer and a per-user cache — the shape every real service
      // has. The registered steps must leave nothing running.
      final chatFeed = StreamController<int>.broadcast();
      final coinFeed = StreamController<int>.broadcast();
      final subs = <StreamSubscription<int>>[
        chatFeed.stream.listen((_) {}),
        coinFeed.stream.listen((_) {}),
      ];
      final heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {});
      final cache = <String, Object>{'old_uid::profile': 1, 'old_uid::chats': 2};

      coordinator
        ..register(SignOutPhase.listeners, 'fake.listeners', (uid) async {
          for (final s in subs) {
            await s.cancel();
          }
          heartbeat.cancel();
        })
        ..register(SignOutPhase.localData, 'fake.cache',
            (uid) async => cache.removeWhere((k, _) => k.startsWith('$uid::')));
      when(() => repository.signOut()).thenAnswer((_) async => const Right(null));

      final bloc = await signedInBloc();
      bloc.add(const AuthSignOutRequested());
      await expectLater(bloc.stream, emits(isA<AuthUnauthenticated>()));
      await coordinator.waitForPendingSignOut();

      expect(chatFeed.hasListener, isFalse);
      expect(coinFeed.hasListener, isFalse);
      expect(heartbeat.isActive, isFalse);
      expect(cache, isEmpty);
      await bloc.close();
      await chatFeed.close();
      await coinFeed.close();
    });

    test('PresenceService.endSession stops timers, writes offline once and '
        'can never mark the old user online again', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('profiles').doc('old_uid').set({'isOnline': false});
      final presence = PresenceService(userId: 'old_uid', firestore: db);
      await presence.onAppResumed();
      expect(presence.hasActiveTimers, isTrue);
      expect((await db.collection('profiles').doc('old_uid').get())['isOnline'],
          isTrue);

      await presence.endSession();
      expect(presence.hasActiveTimers, isFalse);
      expect(PresenceService.instance, isNull);
      expect((await db.collection('profiles').doc('old_uid').get())['isOnline'],
          isFalse);

      presence.recordActivity(); // late tap from a dying widget
      await Future<void>.delayed(Duration.zero);
      expect((await db.collection('profiles').doc('old_uid').get())['isOnline'],
          isFalse);
    });

    test('default steps cover listeners, presence, push, media and local data '
        'in that order', () {
      registerDefaultSignOutSteps(coordinator);
      final steps = coordinator.registeredSteps;
      expect(steps, containsAll(<String>[
        'push.sessionStatics',
        'iap.purchaseStreamListener',
        'profile.privateListener',
        'presence.offline',
        'push.deviceToken',
        'media.soundEffects',
        'media.chatTts',
        'cache.sessionStores',
        'cache.hive',
        'cache.services',
        'cache.decodedImages',
        'analytics.userId',
      ]));
      expect(steps.indexOf('profile.privateListener'),
          lessThan(steps.indexOf('presence.offline')));
      expect(steps.indexOf('presence.offline'),
          lessThan(steps.indexOf('push.deviceToken')));
      expect(steps.indexOf('push.deviceToken'),
          lessThan(steps.indexOf('media.chatTts')));
      expect(steps.indexOf('media.chatTts'),
          lessThan(steps.indexOf('cache.hive')));
      // Idempotent registration.
      registerDefaultSignOutSteps(coordinator);
      expect(coordinator.registeredSteps.length, steps.length);
    });
  });
}
