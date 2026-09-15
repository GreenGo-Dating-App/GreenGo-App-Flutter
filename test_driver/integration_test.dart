import 'package:integration_test/integration_test_driver.dart';

/// Driver entry point for `flutter drive`.
///
/// `writeResponseData` persists the binding's `reportData` to
/// `build/integration_response_data.json`. That file is where the suites'
/// real failure messages land: the driver's own console output reports a web
/// failure as a bare method name with an empty body.
Future<void> main() => integrationDriver(
      responseDataCallback: writeResponseData,
    );
