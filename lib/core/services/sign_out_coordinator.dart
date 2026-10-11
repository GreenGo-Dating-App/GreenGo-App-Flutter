import 'dart:async';

import 'package:flutter/foundation.dart';

/// Order in which the background sign-out job ends a user's activities.
///
/// The UI is already on the login page when this runs. Phases run strictly in
/// this order; steps inside a phase run concurrently. The final Firebase /
/// social sign-out ([SignOutCoordinator.start]'s `finalSignOut`) always runs
/// last, so every step that needs a valid auth token (presence write, FCM
/// token removal) still has one.
enum SignOutPhase {
  /// 1) Cancel snapshot listeners, stream subscriptions, timers, queues.
  listeners,

  /// 2) Presence → offline / lastSeen (while still authenticated).
  presence,

  /// 3) Push: remove this device's token server-side, delete the FCM token,
  ///    cancel shown local notifications.
  push,

  /// 4) Stop audio / TTS / video / location tracking / live sharing.
  media,

  /// 5) Clear per-user local data (caches, stores, prefs, analytics ids).
  localData,
}

/// A single cleanup action. Receives the uid of the user being signed out
/// (null if it could not be determined).
typedef SignOutStep = Future<void> Function(String? uid);

class _RegisteredStep {
  _RegisteredStep(this.phase, this.name, this.run);
  final SignOutPhase phase;
  final String name;
  final SignOutStep run;
}

/// Result of one step, kept for diagnostics and tests.
class SignOutStepResult {
  const SignOutStepResult(this.name, {this.error});
  final String name;
  final Object? error;
  bool get ok => error == null;
  @override
  String toString() => ok ? '$name: ok' : '$name: FAILED ($error)';
}

/// Runs "instant logout": the caller flips the UI to signed-out immediately
/// and this coordinator ends every activity of the old user in the background
/// — listeners → presence → push → media → local data → provider sign-outs.
///
/// * Every step is isolated (try/catch + timeout) so one failure or hang never
///   blocks the others; errors are logged, never surfaced to the user.
/// * The final sign-out is retried once.
/// * The whole job is exposed as [pending]; every sign-in path awaits
///   [waitForPendingSignOut] first so a fast re-login can neither race the old
///   session's teardown nor be killed by the old `signOut()`.
class SignOutCoordinator {
  SignOutCoordinator({
    this.stepTimeout = const Duration(seconds: 8),
    this.signOutTimeout = const Duration(seconds: 15),
  });

  /// App-wide instance. Steps are registered at startup
  /// (see `registerDefaultSignOutSteps`).
  static SignOutCoordinator instance = SignOutCoordinator();

  final Duration stepTimeout;
  final Duration signOutTimeout;

  final List<_RegisteredStep> _steps = [];
  Future<void>? _pending;
  String? _signingOutUid;
  List<SignOutStepResult> _lastResults = const [];

  /// Registers a cleanup step. Re-registering the same [name] replaces it, so
  /// hot restart / repeated setup never runs a step twice.
  void register(SignOutPhase phase, String name, SignOutStep step) {
    _steps.removeWhere((s) => s.name == name);
    _steps.add(_RegisteredStep(phase, name, step));
  }

  /// Names of all registered steps, in execution order.
  List<String> get registeredSteps {
    final sorted = [..._steps]
      ..sort((a, b) => a.phase.index.compareTo(b.phase.index));
    return [for (final s in sorted) s.name];
  }

  /// The running background sign-out job, or null when none is in flight.
  Future<void>? get pending => _pending;

  bool get isSigningOut => _pending != null;

  /// uid being signed out while [isSigningOut]; used to ignore stale
  /// "still signed in" auth events for that user.
  String? get signingOutUid => _signingOutUid;

  /// Results of the last completed job (diagnostics / tests).
  List<SignOutStepResult> get lastResults => _lastResults;

  /// Completes once no sign-out is in flight. Never throws.
  Future<void> waitForPendingSignOut() async {
    // Loop: a second sign-out could start while we waited on the first.
    while (_pending != null) {
      try {
        await _pending;
      } catch (_) {}
    }
  }

  /// Starts the background job (or joins the one already running) and
  /// returns it. The returned future never throws.
  Future<void> start({
    required String? uid,
    required Future<void> Function() finalSignOut,
  }) {
    final existing = _pending;
    if (existing != null) return existing;
    _signingOutUid = uid;
    late final Future<void> job;
    job = _run(uid, finalSignOut).whenComplete(() {
      if (identical(_pending, job)) {
        _pending = null;
        _signingOutUid = null;
      }
    });
    _pending = job;
    return job;
  }

  Future<void> _run(String? uid, Future<void> Function() finalSignOut) async {
    final results = <SignOutStepResult>[];
    for (final phase in SignOutPhase.values) {
      final steps = _steps.where((s) => s.phase == phase).toList();
      if (steps.isEmpty) continue;
      results.addAll(await Future.wait(steps.map((s) => _guard(s, uid))));
    }

    // 6) Social provider sign-outs + firebaseAuth.signOut(), retried once.
    Object? signOutError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await finalSignOut().timeout(signOutTimeout);
        signOutError = null;
        break;
      } catch (e) {
        signOutError = e;
        debugPrint('[SignOut] auth sign-out attempt $attempt failed: $e');
      }
    }
    results.add(SignOutStepResult('auth.signOut', error: signOutError));
    _lastResults = List.unmodifiable(results);

    final failed = results.where((r) => !r.ok).toList();
    debugPrint('[SignOut] done: ${results.length - failed.length}/'
        '${results.length} steps ok${failed.isEmpty ? '' : ' — $failed'}');
  }

  Future<SignOutStepResult> _guard(_RegisteredStep step, String? uid) async {
    try {
      await Future.sync(() => step.run(uid)).timeout(stepTimeout);
      return SignOutStepResult(step.name);
    } catch (e) {
      debugPrint('[SignOut] step ${step.name} failed: $e');
      return SignOutStepResult(step.name, error: e);
    }
  }

  @visibleForTesting
  void debugReset() {
    _steps.clear();
    _pending = null;
    _signingOutUid = null;
    _lastResults = const [];
  }
}
