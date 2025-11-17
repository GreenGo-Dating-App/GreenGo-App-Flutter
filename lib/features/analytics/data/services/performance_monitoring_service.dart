/**
 * Performance Monitoring Service
 * Points 261-270: Firebase Performance Monitoring integration
 */

import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/performance_metrics.dart';

class PerformanceMonitoringService {
  final FirebasePerformance _performance = FirebasePerformance.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  final Map<String, Trace> _activeTraces = {};
  final Map<String, HttpMetric> _activeHttpMetrics = {};

  /// Initialize performance monitoring (Point 261)
  Future<void> initialize() async {
    await _performance.setPerformanceCollectionEnabled(true);

    // Configure Crashlytics (Point 263)
    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      _crashlytics.recordFlutterFatalError(details);
    };

    // Set up Dart error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Start custom trace (Point 262)
  Future<void> startTrace(String traceName) async {
    if (_activeTraces.containsKey(traceName)) {
      // Trace already running
      return;
    }

    final trace = _performance.newTrace(traceName);
    await trace.start();
    _activeTraces[traceName] = trace;
  }

  /// Stop custom trace (Point 262)
  Future<void> stopTrace(String traceName) async {
    final trace = _activeTraces[traceName];
    if (trace == null) {
      return;
    }

    await trace.stop();
    _activeTraces.remove(traceName);
  }

  /// Add metric to trace
  Future<void> setTraceMetric({
    required String traceName,
    required String metricName,
    required int value,
  }) async {
    final trace = _activeTraces[traceName];
    if (trace == null) {
      return;
    }

    trace.setMetric(metricName, value);
  }

  /// Add attribute to trace
  Future<void> setTraceAttribute({
    required String traceName,
    required String attribute,
    required String value,
  }) async {
    final trace = _activeTraces[traceName];
    if (trace == null) {
      return;
    }

    trace.putAttribute(attribute, value);
  }

  /// Track critical operation (Point 262)
  Future<T> trackOperation<T>({
    required CriticalTrace operation,
    required Future<T> Function() execute,
    Map<String, String>? attributes,
  }) async {
    final traceName = operation.traceName;
    await startTrace(traceName);

    if (attributes != null) {
      for (final entry in attributes.entries) {
        await setTraceAttribute(
          traceName: traceName,
          attribute: entry.key,
          value: entry.value,
        );
      }
    }

    try {
      final result = await execute();
      await stopTrace(traceName);

      // Check if exceeds budget
      final trace = _activeTraces[traceName];
      if (trace != null) {
        // Budget checking would be done in analytics
        await _logPerformanceBudget(operation, trace);
      }

      return result;
    } catch (e, stackTrace) {
      await stopTrace(traceName);
      await recordError(e, stackTrace, fatal: false);
      rethrow;
    }
  }

  /// Log performance budget violation (Point 265)
  Future<void> _logPerformanceBudget(
    CriticalTrace operation,
    Trace trace,
  ) async {
    // This would be sent to analytics
    // The actual duration is tracked by Firebase Performance
  }

  /// Start HTTP metric (Point 267)
  Future<void> startHttpMetric({
    required String url,
    required String httpMethod,
  }) async {
    final metricKey = '$httpMethod:$url';

    if (_activeHttpMetrics.containsKey(metricKey)) {
      return;
    }

    final Uri uri = Uri.parse(url);
    final metric = _performance.newHttpMetric(url, HttpMethod.values.firstWhere(
      (m) => m.name.toUpperCase() == httpMethod.toUpperCase(),
      orElse: () => HttpMethod.Get,
    ));

    await metric.start();
    _activeHttpMetrics[metricKey] = metric;
  }

  /// Stop HTTP metric (Point 267)
  Future<void> stopHttpMetric({
    required String url,
    required String httpMethod,
    required int statusCode,
    required int? responseSize,
  }) async {
    final metricKey = '$httpMethod:$url';
    final metric = _activeHttpMetrics[metricKey];

    if (metric == null) {
      return;
    }

    metric.httpResponseCode = statusCode;

    if (responseSize != null) {
      metric.responsePayloadSize = responseSize;
    }

    await metric.stop();
    _activeHttpMetrics.remove(metricKey);
  }

  /// Record error (Point 263)
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    if (customKeys != null) {
      for (final entry in customKeys.entries) {
        await _crashlytics.setCustomKey(
          entry.key,
          entry.value.toString(),
        );
      }
    }

    await _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      printDetails: kDebugMode,
    );
  }

  /// Record Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterError(details);
  }

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  /// Add breadcrumb for debugging
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Set custom keys for crash context
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (final entry in keys.entries) {
      await _crashlytics.setCustomKey(
        entry.key,
        entry.value.toString(),
      );
    }
  }

  /// Track app launch time (Point 265)
  Future<void> trackAppLaunch() async {
    await startTrace('app_launch');
  }

  /// Complete app launch tracking
  Future<void> completeAppLaunch() async {
    await stopTrace('app_launch');
  }

  /// Track screen transition (Point 265)
  Future<void> trackScreenTransition(
    String fromScreen,
    String toScreen,
  ) async {
    final traceName = 'screen_transition_${fromScreen}_to_$toScreen';
    await startTrace(traceName);

    // Will be stopped when transition completes
    // Usually called in navigation observer
  }

  /// Complete screen transition
  Future<void> completeScreenTransition(
    String fromScreen,
    String toScreen,
  ) async {
    final traceName = 'screen_transition_${fromScreen}_to_$toScreen';
    await stopTrace(traceName);
  }

  /// Detect ANR (Application Not Responding) - Point 264
  /// This is primarily for Android and would be detected by platform-specific code
  Future<void> reportANR({
    required Duration blockDuration,
    required String threadName,
    required String stackTrace,
    String? causingOperation,
  }) async {
    await recordError(
      'ANR Detected: ${causingOperation ?? 'Unknown operation'}',
      StackTrace.fromString(stackTrace),
      fatal: false,
      customKeys: {
        'anr_block_duration': blockDuration.inMilliseconds,
        'thread_name': threadName,
        'causing_operation': causingOperation ?? 'unknown',
      },
    );
  }

  /// Track memory usage (Point 269)
  Future<void> trackMemoryUsage({
    required int usedMemoryMB,
    required int totalMemoryMB,
    required double usagePercentage,
  }) async {
    if (usagePercentage > 80.0) {
      await log('High memory usage detected: ${usagePercentage.toStringAsFixed(1)}%');

      // Record as non-fatal error if critical
      if (usagePercentage > 90.0) {
        await recordError(
          'Critical memory usage',
          StackTrace.current,
          fatal: false,
          customKeys: {
            'used_memory_mb': usedMemoryMB,
            'total_memory_mb': totalMemoryMB,
            'usage_percentage': usagePercentage,
          },
        );
      }
    }
  }

  /// Report memory leak (Point 269)
  Future<void> reportMemoryLeak({
    required String className,
    required int instanceCount,
    required int expectedCount,
    required String suspectedCause,
  }) async {
    await recordError(
      'Memory leak detected: $className',
      StackTrace.current,
      fatal: false,
      customKeys: {
        'class_name': className,
        'instance_count': instanceCount,
        'expected_count': expectedCount,
        'suspected_cause': suspectedCause,
      },
    );
  }

  /// Track battery usage (Point 268)
  Future<void> trackBatteryUsage({
    required double drainPerHour,
    required int batteryLevel,
  }) async {
    if (drainPerHour > 10.0) {
      await log('Excessive battery drain: ${drainPerHour.toStringAsFixed(1)}% per hour');

      await setCustomKeys({
        'battery_drain_per_hour': drainPerHour,
        'battery_level': batteryLevel,
      });
    }
  }

  /// Track network failure (Point 267)
  Future<void> trackNetworkFailure({
    required String endpoint,
    required int statusCode,
    required String errorMessage,
  }) async {
    await recordError(
      'Network request failed: $endpoint',
      StackTrace.current,
      fatal: false,
      customKeys: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error_message': errorMessage,
      },
    );
  }

  /// Get crash-free users percentage
  Future<double> getCrashFreeUsersPercentage() async {
    // This would typically be retrieved from Firebase Console
    // or calculated from analytics data
    return 99.5; // Placeholder
  }

  /// Force crash (for testing)
  Future<void> forceCrash() async {
    await _crashlytics.crash();
  }

  /// Test crash reporting (non-fatal)
  Future<void> testCrashReporting() async {
    await recordError(
      Exception('Test exception for crash reporting'),
      StackTrace.current,
      fatal: false,
      customKeys: {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
