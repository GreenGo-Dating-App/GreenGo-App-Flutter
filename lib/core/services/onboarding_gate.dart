import 'dart:async';

/// Coordinates first-login prompts so they appear one after another instead of
/// stacking on top of each other.
///
/// The notification-permission prompt (fired from the app shell during the
/// post-login splash) awaits [guidelinesHandled] so it only shows AFTER the
/// first-run community-guidelines gate has been shown or skipped. The gesture
/// tour then follows naturally (it waits for the discovery cards to load).
class OnboardingGate {
  OnboardingGate._();

  static Completer<void> _guidelines = Completer<void>();

  /// Completes once the community-guidelines gate has been handled. The
  /// notification prompt awaits this (with its own timeout fallback).
  static Future<void> get guidelinesHandled => _guidelines.future;

  /// Called by the main navigation screen after the guidelines gate is shown
  /// or determined unnecessary.
  static void markGuidelinesHandled() {
    if (!_guidelines.isCompleted) _guidelines.complete();
  }

  /// Reset on logout so the next account re-sequences from scratch.
  static void reset() {
    if (!_guidelines.isCompleted) _guidelines.complete();
    _guidelines = Completer<void>();
  }
}
