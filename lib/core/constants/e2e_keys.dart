import 'package:flutter/widgets.dart';

/// Stable widget keys for the end-to-end suites.
///
/// Kept in `lib/` on purpose: the app and the tests must agree on one set of
/// identifiers, and a key defined in the test tree cannot be attached to a
/// production widget. Nothing here affects runtime behaviour — a [Key] only
/// changes how the element tree is reconciled, and these are all unique.
///
/// Rule for adding one: a control an end-to-end test has to touch gets a key.
/// Everything else stays findable by its localized label, which the suites read
/// from the same ARB file the app renders from.
class E2EKeys {
  const E2EKeys._();

  // --- Authentication -------------------------------------------------------
  static const loginEmail = Key('e2e_login_email');
  static const loginPassword = Key('e2e_login_password');
  static const loginSubmit = Key('e2e_login_submit');
  static const loginForgotPassword = Key('e2e_login_forgot_password');
  static const loginSignUpLink = Key('e2e_login_signup_link');

  static const registerEmail = Key('e2e_register_email');
  static const registerPassword = Key('e2e_register_password');
  static const registerConfirmPassword = Key('e2e_register_confirm_password');
  static const registerSubmit = Key('e2e_register_submit');

  static const forgotPasswordEmail = Key('e2e_forgot_email');
  static const forgotPasswordSubmit = Key('e2e_forgot_submit');

  // --- Shells and gates -----------------------------------------------------
  static const splash = Key('e2e_splash');
  static const postLoginSplash = Key('e2e_post_login_splash');
  static const mainNavigation = Key('e2e_main_navigation');
  static const bannedScreen = Key('e2e_banned_screen');
  static const waitingScreen = Key('e2e_waiting_screen');
  static const errorScreen = Key('e2e_error_screen');
  static const onboardingScreen = Key('e2e_onboarding_screen');

  // --- Bottom navigation ----------------------------------------------------
  static const navExplore = Key('e2e_nav_explore');
  static const navEvents = Key('e2e_nav_events');
  static const navCommunities = Key('e2e_nav_communities');
  static const navMessages = Key('e2e_nav_messages');
  static const navProfile = Key('e2e_nav_profile');
}
