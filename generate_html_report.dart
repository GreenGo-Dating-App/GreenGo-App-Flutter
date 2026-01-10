import 'dart:io';
import 'package:xml/xml.dart';

void main() {
  final xmlFile = File('test_results.xml');
  if (!xmlFile.existsSync()) {
    print('test_results.xml not found');
    exit(1);
  }

  final xmlContent = xmlFile.readAsStringSync();
  final document = XmlDocument.parse(xmlContent);

  final testsuites = document.findAllElements('testsuite');

  int totalTests = 0;
  int totalPassed = 0;
  int totalFailed = 0;
  int totalErrors = 0;
  double totalTime = 0;

  final testResults = <Map<String, dynamic>>[];

  for (final testsuite in testsuites) {
    final tests = int.tryParse(testsuite.getAttribute('tests') ?? '0') ?? 0;
    final failures = int.tryParse(testsuite.getAttribute('failures') ?? '0') ?? 0;
    final errors = int.tryParse(testsuite.getAttribute('errors') ?? '0') ?? 0;
    final time = double.tryParse(testsuite.getAttribute('time') ?? '0') ?? 0;

    totalTests += tests;
    totalFailed += failures;
    totalErrors += errors;
    totalTime += time;

    for (final testcase in testsuite.findElements('testcase')) {
      final name = testcase.getAttribute('name') ?? 'Unknown';
      final classname = testcase.getAttribute('classname') ?? '';
      final testTime = double.tryParse(testcase.getAttribute('time') ?? '0') ?? 0;
      final failure = testcase.findElements('failure').firstOrNull;
      final error = testcase.findElements('error').firstOrNull;

      String status = 'passed';
      String? message;

      if (failure != null) {
        status = 'failed';
        message = failure.innerText;
      } else if (error != null) {
        status = 'error';
        message = error.innerText;
      }

      if (status == 'passed') totalPassed++;

      testResults.add({
        'name': name,
        'classname': classname,
        'time': testTime,
        'status': status,
        'message': message,
      });
    }
  }

  final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GreenGo App - Test Report</title>
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            margin: 0; padding: 20px; background: #f5f5f5;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #2e7d32; margin-bottom: 10px; }
        .summary {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px; margin: 20px 0;
        }
        .card {
            background: white; padding: 20px; border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center;
        }
        .card h3 { margin: 0 0 10px 0; color: #666; font-size: 14px; }
        .card .value { font-size: 32px; font-weight: bold; }
        .card.total .value { color: #1976d2; }
        .card.passed .value { color: #2e7d32; }
        .card.failed .value { color: #d32f2f; }
        .card.time .value { color: #f57c00; font-size: 24px; }
        .progress-bar {
            height: 8px; background: #e0e0e0; border-radius: 4px;
            overflow: hidden; margin: 20px 0;
        }
        .progress-fill {
            height: 100%; background: #4caf50; border-radius: 4px;
            transition: width 0.3s;
        }
        .test-list { background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .test-item {
            padding: 12px 20px; border-bottom: 1px solid #eee;
            display: flex; justify-content: space-between; align-items: center;
        }
        .test-item:last-child { border-bottom: none; }
        .test-item:hover { background: #f9f9f9; }
        .test-name { flex: 1; }
        .test-status {
            padding: 4px 12px; border-radius: 12px; font-size: 12px;
            font-weight: 600; text-transform: uppercase;
        }
        .test-status.passed { background: #e8f5e9; color: #2e7d32; }
        .test-status.failed { background: #ffebee; color: #d32f2f; }
        .test-time { color: #999; font-size: 12px; margin-left: 10px; min-width: 60px; text-align: right; }
        .header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; }
        .timestamp { color: #666; font-size: 14px; }
        .filter-buttons { margin: 20px 0; }
        .filter-btn {
            padding: 8px 16px; margin-right: 10px; border: none;
            border-radius: 4px; cursor: pointer; font-size: 14px;
        }
        .filter-btn.active { background: #2e7d32; color: white; }
        .filter-btn:not(.active) { background: #e0e0e0; }
        .category {
            font-size: 11px; color: #999; display: block;
            margin-top: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌱 GreenGo App - Test Report</h1>
            <span class="timestamp">Generated: ${DateTime.now().toString().substring(0, 19)}</span>
        </div>

        <div class="summary">
            <div class="card total">
                <h3>TOTAL TESTS</h3>
                <div class="value">$totalTests</div>
            </div>
            <div class="card passed">
                <h3>PASSED</h3>
                <div class="value">$totalPassed</div>
            </div>
            <div class="card failed">
                <h3>FAILED</h3>
                <div class="value">${totalFailed + totalErrors}</div>
            </div>
            <div class="card time">
                <h3>DURATION</h3>
                <div class="value">${totalTime.toStringAsFixed(2)}s</div>
            </div>
        </div>

        <div class="progress-bar">
            <div class="progress-fill" style="width: ${totalTests > 0 ? (totalPassed / totalTests * 100) : 0}%"></div>
        </div>

        <h2>Test Results</h2>
        <div class="test-list">
            ${testResults.map((test) => '''
            <div class="test-item">
                <div class="test-name">
                    ${test['name']}
                    <span class="category">${test['classname']}</span>
                </div>
                <span class="test-status ${test['status']}">${test['status']}</span>
                <span class="test-time">${(test['time'] as double).toStringAsFixed(3)}s</span>
            </div>
            ''').join('')}
        </div>
    </div>
</body>
</html>
''';

  File('test_report.html').writeAsStringSync(html);
  print('HTML report generated: test_report.html');
  print('Total: $totalTests | Passed: $totalPassed | Failed: ${totalFailed + totalErrors}');
}
