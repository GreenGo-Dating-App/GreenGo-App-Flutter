import 's01_boot_session_test.dart' as boot;
import 's02_registration_test.dart' as registration;
import 's03_auth_test.dart' as auth;
import 's04_access_gate_test.dart' as gate;
import 's05_discovery_test.dart' as discovery;
import 's06_chat_test.dart' as chat;
import 's07_groups_communities_test.dart' as groups;
import 's08_events_test.dart' as events;
import 's09_payments_test.dart' as payments;
import 's10_notifications_test.dart' as notifications;
import 's11_profile_settings_test.dart' as profile;

/// Runs all 95 widget-level end-to-end scenarios in one driver session.
///
/// The other five (BOOT-04, BOOT-05, BOOT-09, NOTIF-03, PROF-08) are
/// browser-level and run from `tool/e2e_web/web_suite.py`.
///
/// Order matters: boot and auth run first, so a failure in the session
/// machinery is reported as itself rather than as forty downstream failures
/// that all mean "could not log in".
void main() {
  boot.main();
  auth.main();
  gate.main();
  registration.main();
  discovery.main();
  chat.main();
  groups.main();
  events.main();
  payments.main();
  notifications.main();
  profile.main();
}
