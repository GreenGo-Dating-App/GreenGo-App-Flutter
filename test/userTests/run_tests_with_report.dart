import 'dart:io';

/// Convenience script to run all user tests and generate a report
///
/// Usage: dart run tests/userTests/run_tests_with_report.dart
///
/// This script will:
/// 1. Run all 100 user tests
/// 2. Generate test_output.json with results
/// 3. Generate test_report.html with detailed report

void main() async {
  print('╔════════════════════════════════════════════════════════╗');
  print('║     GreenGo Chat - Run Tests & Generate Report         ║');
  print('╚════════════════════════════════════════════════════════╝\n');

  // Step 1: Run tests with machine output
  print('🧪 Running user tests...\n');

  final testProcess = await Process.start(
    'flutter',
    ['test', '--machine', 'tests/userTests/'],
    runInShell: true,
  );

  // Capture output to file
  final outputFile = File('test_output.json');
  final sink = outputFile.openWrite();

  // Stream stdout to file and console
  testProcess.stdout.listen((data) {
    sink.add(data);
    stdout.add(data);
  });

  // Stream stderr to console
  testProcess.stderr.listen((data) {
    stderr.add(data);
  });

  // Wait for test completion
  final exitCode = await testProcess.exitCode;
  await sink.close();

  print('\n');

  if (exitCode != 0) {
    print('⚠️  Some tests failed (exit code: $exitCode)');
  } else {
    print('✅ All tests passed!');
  }

  // Step 2: Generate report
  print('\n📊 Generating test report...\n');

  final reportProcess = await Process.run(
    'dart',
    ['run', 'tests/userTests/test_report_generator.dart'],
    runInShell: true,
  );

  print(reportProcess.stdout);

  if (reportProcess.stderr.toString().isNotEmpty) {
    print(reportProcess.stderr);
  }

  print('\n✨ Done! Open test_report.html to view the detailed report.');
}
