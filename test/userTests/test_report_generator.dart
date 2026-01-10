import 'dart:io';
import 'dart:convert';

/// Test Report Generator for GreenGo Chat User Tests
///
/// This script parses test output and generates a comprehensive HTML report.
///
/// Usage:
///   1. Run tests with machine output:
///      flutter test --machine tests/userTests/ > test_output.json
///
///   2. Generate report:
///      dart run tests/userTests/test_report_generator.dart
///
///   Or use the convenience script:
///      dart run tests/userTests/run_tests_with_report.dart

class TestResult {
  final String name;
  final String group;
  final bool passed;
  final String? error;
  final int duration; // in milliseconds

  TestResult({
    required this.name,
    required this.group,
    required this.passed,
    this.error,
    required this.duration,
  });
}

class TestCategory {
  final String name;
  final int total;
  int passed = 0;
  int failed = 0;
  List<TestResult> tests = [];

  TestCategory(this.name, this.total);
}

void main() async {
  print('╔════════════════════════════════════════════════════════╗');
  print('║     GreenGo Chat - User Test Report Generator          ║');
  print('╚════════════════════════════════════════════════════════╝\n');

  // Check if test output file exists
  final testOutputFile = File('test_output.json');

  if (!await testOutputFile.exists()) {
    print('⚠️  No test output file found.');
    print('');
    print('To generate a test report:');
    print('1. Run: flutter test --machine tests/userTests/ > test_output.json');
    print('2. Then run this script again.');
    print('');
    print('Generating sample report with test structure...\n');
    await generateSampleReport();
    return;
  }

  // Parse test output
  final content = await testOutputFile.readAsString();
  final results = parseTestOutput(content);

  // Generate report
  await generateReport(results);
}

List<TestResult> parseTestOutput(String content) {
  final results = <TestResult>[];
  final lines = content.split('\n');
  final testStarts = <int, Map<String, dynamic>>{};
  final testTimes = <int, int>{};

  for (final line in lines) {
    if (line.isEmpty) continue;

    try {
      final json = jsonDecode(line);

      // Track test starts
      if (json['type'] == 'testStart') {
        final test = json['test'] as Map<String, dynamic>?;
        if (test != null) {
          final id = test['id'] as int;
          final name = test['name'] as String? ?? 'Unknown';
          // Skip loading tests
          if (!name.startsWith('loading ')) {
            testStarts[id] = test;
            testTimes[id] = json['time'] as int? ?? 0;
          }
        }
      }

      // Match with test done
      if (json['type'] == 'testDone') {
        final testId = json['testID'] as int?;
        final hidden = json['hidden'] as bool? ?? false;

        if (testId != null && !hidden && testStarts.containsKey(testId)) {
          final test = testStarts[testId]!;
          final testName = test['name'] as String? ?? 'Unknown';
          final result = json['result'] as String;
          final endTime = json['time'] as int? ?? 0;
          final startTime = testTimes[testId] ?? 0;
          final duration = endTime - startTime;

          results.add(TestResult(
            name: testName,
            group: extractGroup(testName),
            passed: result == 'success',
            error: json['error'] as String?,
            duration: duration,
          ));
        }
      }
    } catch (e) {
      // Skip malformed lines
    }
  }

  return results;
}

String extractGroup(String testName) {
  if (testName.contains('Authentication')) return 'Authentication';
  if (testName.contains('Onboarding')) return 'Onboarding';
  if (testName.contains('Profile')) return 'Profile Editing';
  if (testName.contains('Discovery') || testName.contains('Swip')) return 'Discovery & Swiping';
  if (testName.contains('Match')) return 'Matching';
  if (testName.contains('Consent') || testName.contains('privacy') || testName.contains('terms')) return 'Consent Checkboxes';
  if (testName.contains('Translation') || testName.contains('Translate') || testName.contains('translate')) return 'Chat Translation';
  if (testName.contains('Chat') || testName.contains('Message') || testName.contains('message')) return 'Chat & Messaging';
  if (testName.contains('Notification')) return 'Notifications';
  if (testName.contains('Achievement') || testName.contains('Challenge') || testName.contains('Leaderboard')) return 'Gamification';
  if (testName.contains('Coin') || testName.contains('Shop')) return 'Coins & Shop';
  if (testName.contains('Subscription') || testName.contains('Premium')) return 'Subscription';
  if (testName.contains('Setting') || testName.contains('Language')) return 'Settings';
  return 'Other';
}

Future<void> generateReport(List<TestResult> results) async {
  final timestamp = DateTime.now();
  final totalTests = results.length;
  final passedTests = results.where((r) => r.passed).length;
  final failedTests = totalTests - passedTests;
  final passRate = totalTests > 0 ? (passedTests / totalTests * 100).toStringAsFixed(1) : '0';
  final totalDuration = results.fold(0, (sum, r) => sum + r.duration);

  // Group results by category
  final categories = <String, List<TestResult>>{};
  for (final result in results) {
    categories.putIfAbsent(result.group, () => []).add(result);
  }

  // Generate HTML report
  final htmlReport = generateHtmlReport(
    timestamp: timestamp,
    totalTests: totalTests,
    passedTests: passedTests,
    failedTests: failedTests,
    passRate: passRate,
    totalDuration: totalDuration,
    categories: categories,
    results: results,
  );

  // Save reports
  final htmlFile = File('test_report.html');
  await htmlFile.writeAsString(htmlReport);

  // Generate console summary
  printConsoleSummary(
    timestamp: timestamp,
    totalTests: totalTests,
    passedTests: passedTests,
    failedTests: failedTests,
    passRate: passRate,
    totalDuration: totalDuration,
    categories: categories,
  );

  print('\n📊 Reports generated:');
  print('   - test_report.html (detailed HTML report)');
}

Future<void> generateSampleReport() async {
  final categories = {
    'Authentication': TestCategory('Authentication', 15),
    'Onboarding': TestCategory('Onboarding', 12),
    'Profile Editing': TestCategory('Profile Editing', 10),
    'Discovery & Swiping': TestCategory('Discovery & Swiping', 12),
    'Matching': TestCategory('Matching', 8),
    'Chat & Messaging': TestCategory('Chat & Messaging', 12),
    'Notifications': TestCategory('Notifications', 8),
    'Gamification': TestCategory('Gamification', 10),
    'Coins & Shop': TestCategory('Coins & Shop', 6),
    'Subscription': TestCategory('Subscription', 4),
    'Settings': TestCategory('Settings', 3),
  };

  final htmlReport = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GreenGo Chat - Test Report</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; }
        .header h1 { font-size: 2em; margin-bottom: 10px; }
        .header p { opacity: 0.9; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 8px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-card h3 { font-size: 2em; color: #2e7d32; }
        .stat-card p { color: #666; font-size: 0.9em; }
        .categories { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .category { border-bottom: 1px solid #eee; padding: 15px 0; }
        .category:last-child { border-bottom: none; }
        .category-header { display: flex; justify-content: space-between; align-items: center; }
        .category-name { font-weight: 600; }
        .category-count { background: #e8f5e9; color: #2e7d32; padding: 4px 12px; border-radius: 20px; font-size: 0.85em; }
        .test-list { margin-top: 15px; padding-left: 20px; }
        .test-item { padding: 8px 0; border-bottom: 1px solid #f5f5f5; display: flex; align-items: center; }
        .test-item:last-child { border-bottom: none; }
        .test-status { width: 20px; height: 20px; border-radius: 50%; margin-right: 10px; display: flex; align-items: center; justify-content: center; font-size: 12px; }
        .pending { background: #fff3e0; color: #e65100; }
        .passed { background: #e8f5e9; color: #2e7d32; }
        .failed { background: #ffebee; color: #c62828; }
        .footer { text-align: center; margin-top: 20px; color: #999; font-size: 0.85em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>GreenGo Chat - User Test Report</h1>
            <p>Generated: ${DateTime.now().toString().split('.')[0]}</p>
        </div>

        <div class="summary">
            <div class="stat-card">
                <h3>100</h3>
                <p>Total Tests</p>
            </div>
            <div class="stat-card">
                <h3>-</h3>
                <p>Passed</p>
            </div>
            <div class="stat-card">
                <h3>-</h3>
                <p>Failed</p>
            </div>
            <div class="stat-card">
                <h3>-</h3>
                <p>Pass Rate</p>
            </div>
        </div>

        <div class="categories">
            <h2 style="margin-bottom: 20px;">Test Categories</h2>
            ${categories.entries.map((e) => '''
            <div class="category">
                <div class="category-header">
                    <span class="category-name">${e.key}</span>
                    <span class="category-count">${e.value.total} tests</span>
                </div>
            </div>
            ''').join('')}
        </div>

        <div class="footer">
            <p>Run tests to see detailed results: flutter test --machine tests/userTests/ > test_output.json</p>
        </div>
    </div>
</body>
</html>
''';

  final htmlFile = File('test_report.html');
  await htmlFile.writeAsString(htmlReport);

  print('Test Structure Summary:');
  print('═══════════════════════════════════════════════════════\n');

  int total = 0;
  for (final entry in categories.entries) {
    print('${entry.key}: ${entry.value.total} tests');
    total += entry.value.total;
  }

  print('\n═══════════════════════════════════════════════════════');
  print('Total: $total tests\n');

  print('📊 Sample report generated: test_report.html');
  print('\nTo run actual tests:');
  print('   flutter test --machine tests/userTests/ > test_output.json');
  print('   dart run tests/userTests/test_report_generator.dart');
}

String generateHtmlReport({
  required DateTime timestamp,
  required int totalTests,
  required int passedTests,
  required int failedTests,
  required String passRate,
  required int totalDuration,
  required Map<String, List<TestResult>> categories,
  required List<TestResult> results,
}) {
  return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GreenGo Chat - Test Report</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; }
        .header h1 { font-size: 2em; margin-bottom: 10px; }
        .header p { opacity: 0.9; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 8px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-card h3 { font-size: 2em; color: #2e7d32; }
        .stat-card p { color: #666; font-size: 0.9em; }
        .stat-card.failed h3 { color: #c62828; }
        .categories { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .category { border-bottom: 1px solid #eee; padding: 15px 0; }
        .category:last-child { border-bottom: none; }
        .category-header { display: flex; justify-content: space-between; align-items: center; cursor: pointer; }
        .category-name { font-weight: 600; }
        .category-count { background: #e8f5e9; color: #2e7d32; padding: 4px 12px; border-radius: 20px; font-size: 0.85em; }
        .category-count.has-failures { background: #ffebee; color: #c62828; }
        .test-list { margin-top: 15px; }
        .test-item { padding: 8px 15px; border-radius: 4px; margin: 5px 0; display: flex; align-items: center; background: #fafafa; }
        .test-status { width: 24px; height: 24px; border-radius: 50%; margin-right: 12px; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: bold; }
        .passed .test-status { background: #e8f5e9; color: #2e7d32; }
        .failed .test-status { background: #ffebee; color: #c62828; }
        .test-name { flex: 1; }
        .test-duration { color: #999; font-size: 0.85em; }
        .error-message { background: #ffebee; color: #c62828; padding: 10px; margin-top: 5px; border-radius: 4px; font-size: 0.85em; }
        .footer { text-align: center; margin-top: 20px; color: #999; font-size: 0.85em; }
        .progress-bar { height: 8px; background: #e0e0e0; border-radius: 4px; overflow: hidden; margin-top: 10px; }
        .progress-fill { height: 100%; background: #4caf50; border-radius: 4px; transition: width 0.3s; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>GreenGo Chat - User Test Report</h1>
            <p>Generated: ${timestamp.toString().split('.')[0]}</p>
        </div>

        <div class="summary">
            <div class="stat-card">
                <h3>$totalTests</h3>
                <p>Total Tests</p>
            </div>
            <div class="stat-card">
                <h3>$passedTests</h3>
                <p>Passed</p>
            </div>
            <div class="stat-card ${failedTests > 0 ? 'failed' : ''}">
                <h3>$failedTests</h3>
                <p>Failed</p>
            </div>
            <div class="stat-card">
                <h3>$passRate%</h3>
                <p>Pass Rate</p>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: $passRate%"></div>
                </div>
            </div>
            <div class="stat-card">
                <h3>${(totalDuration / 1000).toStringAsFixed(1)}s</h3>
                <p>Duration</p>
            </div>
        </div>

        <div class="categories">
            <h2 style="margin-bottom: 20px;">Test Results by Category</h2>
            ${categories.entries.map((e) {
              final passed = e.value.where((t) => t.passed).length;
              final failed = e.value.length - passed;
              final hasFailures = failed > 0;
              return '''
            <div class="category">
                <div class="category-header">
                    <span class="category-name">${e.key}</span>
                    <span class="category-count ${hasFailures ? 'has-failures' : ''}">$passed/${e.value.length} passed</span>
                </div>
                <div class="test-list">
                    ${e.value.map((test) => '''
                    <div class="test-item ${test.passed ? 'passed' : 'failed'}">
                        <div class="test-status">${test.passed ? '✓' : '✗'}</div>
                        <span class="test-name">${test.name}</span>
                        <span class="test-duration">${test.duration}ms</span>
                    </div>
                    ${test.error != null ? '<div class="error-message">${test.error}</div>' : ''}
                    ''').join('')}
                </div>
            </div>
              ''';
            }).join('')}
        </div>

        <div class="footer">
            <p>GreenGo Chat App - User Tests Report</p>
        </div>
    </div>
</body>
</html>
''';
}

void printConsoleSummary({
  required DateTime timestamp,
  required int totalTests,
  required int passedTests,
  required int failedTests,
  required String passRate,
  required int totalDuration,
  required Map<String, List<TestResult>> categories,
}) {
  print('\n📋 TEST REPORT SUMMARY');
  print('══════════════════════════════════════════════════════════');
  print('Generated: ${timestamp.toString().split('.')[0]}');
  print('');
  print('OVERALL RESULTS:');
  print('  Total Tests:  $totalTests');
  print('  Passed:       $passedTests ✓');
  print('  Failed:       $failedTests ${failedTests > 0 ? '✗' : ''}');
  print('  Pass Rate:    $passRate%');
  print('  Duration:     ${(totalDuration / 1000).toStringAsFixed(1)}s');
  print('');
  print('BY CATEGORY:');

  for (final entry in categories.entries) {
    final passed = entry.value.where((t) => t.passed).length;
    final total = entry.value.length;
    final status = passed == total ? '✓' : '!';
    print('  $status ${entry.key}: $passed/$total');
  }

  print('══════════════════════════════════════════════════════════');
}
