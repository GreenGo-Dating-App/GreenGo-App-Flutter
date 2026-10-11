import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/access_log_service.dart';

/// Marco Civil access log (audit BR-09): the app only pings `logAccess`; the
/// server takes IP + time. It must never throw into the sign-in flow.
void main() {
  final original = AccessLogService.call;
  tearDown(() => AccessLogService.call = original);

  test('sign-in and app-session events are sent with the platform', () async {
    final sent = <Map<String, dynamic>>[];
    AccessLogService.call = (p) async => sent.add(p);
    await AccessLogService.send(signIn: true);
    await AccessLogService.send(signIn: false);
    expect(sent.map((p) => p['event']), ['sign_in', 'app_session']);
    expect(sent.every((p) => (p['platform'] as String).isNotEmpty), isTrue);
    expect(sent.first.containsKey('ip'), isFalse,
        reason: 'the IP is taken by the server, never sent by the app');
  });

  test('a failing call is swallowed', () async {
    AccessLogService.call = (p) async => throw Exception('offline');
    await expectLater(AccessLogService.send(signIn: true), completes);
  });
}
