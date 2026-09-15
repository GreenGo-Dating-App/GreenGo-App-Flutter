import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'e2e_harness.dart';

/// Test wrapper that makes failures readable on web.
///
/// `flutter drive -d chrome` reports a failed integration test as
/// "Failure in method: <name>" followed by an empty body — the exception text
/// does not survive the trip from the browser to the driver. That turns a
/// failing suite into a list of names with no reason, which is useless.
///
/// [e2eTest] catches whatever the test threw, records it in the binding's
/// `reportData`, and rethrows so the test still fails. The driver writes
/// `reportData` to `build/integration_response_data.json`, where every error
/// is legible with its stack.
/// [timeout] defaults to five minutes, not the 30 seconds `testWidgets` uses.
/// These tests boot a real app against a real backend and several wait 20-35s
/// for a screen; at the default the framework kills the body mid-await, which
/// loses the result entirely — the test reports as failed with no message, and
/// nothing reaches the sink.
void e2eTest(
  String description,
  Future<void> Function(WidgetTester) body, {
  Timeout timeout = const Timeout(Duration(minutes: 5)),
}) {
  testWidgets(description, timeout: timeout, (tester) async {
    final binding =
        IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    try {
      await E2E.ensureFirebase();
      await body(tester);
      await _record(binding, description, 'passed', null, null);
    } catch (error, stack) {
      _record(binding, description, 'failed', '$error',
          stack.toString().split('\n').take(12).join('\n'));
      rethrow;
    }
  });
}

/// Where the result sink listens. `tool/e2e_sink.py` serves it.
///
/// The driver is not a usable reporting channel: `integrationDriver` prints
/// its (empty, on web) failure details and exits before it ever calls the
/// response-data callback, so a failing web suite reports method names and
/// nothing else. Posting each result out of the browser as it happens is the
/// only channel that survives a failure.
const String _sinkUrl =
    String.fromEnvironment('E2E_SINK', defaultValue: 'http://127.0.0.1:8123/result');

Future<void> _post(Map<String, dynamic> result) async {
  try {
    await http
        .post(Uri.parse(_sinkUrl),
            headers: const {'Content-Type': 'text/plain'},
            body: jsonEncode(result))
        .timeout(const Duration(seconds: 5));
  } catch (_) {
    // No sink running — the run is still valid, just less legible.
  }
}

Future<void> _record(
  IntegrationTestWidgetsFlutterBinding binding,
  String description,
  String status,
  String? error,
  String? stack,
) async {
  final data = Map<String, dynamic>.from(binding.reportData ?? {});
  final results = Map<String, dynamic>.from(
      data['e2e'] as Map<String, dynamic>? ?? <String, dynamic>{});
  results[description] = <String, dynamic>{
    'status': status,
    if (error != null) 'error': error,
    if (stack != null) 'stack': stack,
  };
  data['e2e'] = results;
  binding.reportData = data;

  // Awaited, not fire-and-forget: the browser is torn down between tests and
  // an in-flight request would be lost exactly when a test failed.
  await _post({
    'test': description,
    'status': status,
    if (error != null) 'error': error,
    if (stack != null) 'stack': stack,
  });
}
