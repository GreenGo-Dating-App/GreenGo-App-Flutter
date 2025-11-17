/**
 * Performance Metrics Entity
 * Points 261-270: Performance monitoring and optimization
 */

import 'package:equatable/equatable.dart';

/// Performance trace (Point 262)
class PerformanceTrace extends Equatable {
  final String traceName;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final Map<String, int> metrics;
  final Map<String, String> attributes;

  const PerformanceTrace({
    required this.traceName,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.metrics,
    required this.attributes,
  });

  bool get isCompleted => endTime != null && duration != null;

  @override
  List<Object?> get props => [
        traceName,
        startTime,
        endTime,
        duration,
        metrics,
        attributes,
      ];
}

/// Critical performance traces (Point 262)
enum CriticalTrace {
  profileLoading,
  messageSending,
  videoCallInitialization,
  imageUpload,
  discoveryPageLoad,
  matchesPageLoad,
  conversationLoad,
  subscriptionPageLoad;

  String get traceName {
    switch (this) {
      case CriticalTrace.profileLoading:
        return 'profile_loading';
      case CriticalTrace.messageSending:
        return 'message_sending';
      case CriticalTrace.videoCallInitialization:
        return 'video_call_initialization';
      case CriticalTrace.imageUpload:
        return 'image_upload';
      case CriticalTrace.discoveryPageLoad:
        return 'discovery_page_load';
      case CriticalTrace.matchesPageLoad:
        return 'matches_page_load';
      case CriticalTrace.conversationLoad:
        return 'conversation_load';
      case CriticalTrace.subscriptionPageLoad:
        return 'subscription_page_load';
    }
  }

  Duration get performanceBudget {
    switch (this) {
      case CriticalTrace.profileLoading:
        return const Duration(milliseconds: 800);
      case CriticalTrace.messageSending:
        return const Duration(milliseconds: 500);
      case CriticalTrace.videoCallInitialization:
        return const Duration(seconds: 2);
      case CriticalTrace.imageUpload:
        return const Duration(seconds: 3);
      case CriticalTrace.discoveryPageLoad:
        return const Duration(milliseconds: 600);
      case CriticalTrace.matchesPageLoad:
        return const Duration(milliseconds: 500);
      case CriticalTrace.conversationLoad:
        return const Duration(milliseconds: 400);
      case CriticalTrace.subscriptionPageLoad:
        return const Duration(milliseconds: 700);
    }
  }
}

/// Crash report (Point 263)
class CrashReport extends Equatable {
  final String crashId;
  final DateTime timestamp;
  final String exceptionType;
  final String message;
  final String stackTrace;
  final DeviceInfo deviceInfo;
  final AppInfo appInfo;
  final Map<String, dynamic> customKeys;
  final bool isFatal;

  const CrashReport({
    required this.crashId,
    required this.timestamp,
    required this.exceptionType,
    required this.message,
    required this.stackTrace,
    required this.deviceInfo,
    required this.appInfo,
    required this.customKeys,
    required this.isFatal,
  });

  @override
  List<Object?> get props => [
        crashId,
        timestamp,
        exceptionType,
        message,
        stackTrace,
        deviceInfo,
        appInfo,
        customKeys,
        isFatal,
      ];
}

/// Device information
class DeviceInfo extends Equatable {
  final String platform; // iOS, Android, Web
  final String osVersion;
  final String deviceModel;
  final String deviceManufacturer;
  final String screenResolution;
  final int memoryMB;
  final int storageMB;
  final bool isPhysicalDevice;

  const DeviceInfo({
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.deviceManufacturer,
    required this.screenResolution,
    required this.memoryMB,
    required this.storageMB,
    required this.isPhysicalDevice,
  });

  @override
  List<Object?> get props => [
        platform,
        osVersion,
        deviceModel,
        deviceManufacturer,
        screenResolution,
        memoryMB,
        storageMB,
        isPhysicalDevice,
      ];
}

/// App information
class AppInfo extends Equatable {
  final String appVersion;
  final String buildNumber;
  final String flutterVersion;
  final String dartVersion;

  const AppInfo({
    required this.appVersion,
    required this.buildNumber,
    required this.flutterVersion,
    required this.dartVersion,
  });

  @override
  List<Object?> get props => [
        appVersion,
        buildNumber,
        flutterVersion,
        dartVersion,
      ];
}

/// ANR (Application Not Responding) detection (Point 264)
class ANRReport extends Equatable {
  final String anrId;
  final DateTime timestamp;
  final Duration blockDuration;
  final String threadName;
  final String stackTrace;
  final DeviceInfo deviceInfo;
  final String? causingOperation;

  const ANRReport({
    required this.anrId,
    required this.timestamp,
    required this.blockDuration,
    required this.threadName,
    required this.stackTrace,
    required this.deviceInfo,
    this.causingOperation,
  });

  @override
  List<Object?> get props => [
        anrId,
        timestamp,
        blockDuration,
        threadName,
        stackTrace,
        deviceInfo,
        causingOperation,
      ];
}

/// Performance budget (Point 265)
class PerformanceBudget extends Equatable {
  final String metricName;
  final Duration budgetValue;
  final Duration actualValue;
  final bool isWithinBudget;
  final double variance; // Percentage over/under budget

  const PerformanceBudget({
    required this.metricName,
    required this.budgetValue,
    required this.actualValue,
    required this.isWithinBudget,
    required this.variance,
  });

  @override
  List<Object?> get props => [
        metricName,
        budgetValue,
        actualValue,
        isWithinBudget,
        variance,
      ];
}

/// Performance budgets (Point 265)
class PerformanceBudgets {
  static const Duration appLaunch = Duration(seconds: 2);
  static const Duration screenTransition = Duration(milliseconds: 300);
  static const Duration apiCall = Duration(seconds: 1);
  static const Duration imageLoad = Duration(milliseconds: 800);
  static const Duration videoLoad = Duration(seconds: 2);
  static const Duration databaseQuery = Duration(milliseconds: 500);
}

/// Core Web Vitals for Flutter Web (Point 266)
class CoreWebVitals extends Equatable {
  final double lcp; // Largest Contentful Paint (ms)
  final double fid; // First Input Delay (ms)
  final double cls; // Cumulative Layout Shift (score)
  final double fcp; // First Contentful Paint (ms)
  final double ttfb; // Time to First Byte (ms)
  final DateTime measuredAt;

  const CoreWebVitals({
    required this.lcp,
    required this.fid,
    required this.cls,
    required this.fcp,
    required this.ttfb,
    required this.measuredAt,
  });

  /// Check if metrics pass Core Web Vitals thresholds
  bool get passesLCP => lcp <= 2500; // Good: <= 2.5s
  bool get passesFID => fid <= 100; // Good: <= 100ms
  bool get passesCLS => cls <= 0.1; // Good: <= 0.1

  bool get passesAllVitals => passesLCP && passesFID && passesCLS;

  @override
  List<Object?> get props => [lcp, fid, cls, fcp, ttfb, measuredAt];
}

/// Network performance metrics (Point 267)
class NetworkPerformanceMetrics extends Equatable {
  final String endpoint;
  final Duration latency;
  final int responseSize; // Bytes
  final int statusCode;
  final bool isSuccess;
  final DateTime timestamp;
  final String httpMethod;
  final Duration? connectionTime;
  final Duration? dnsLookupTime;
  final Duration? sslHandshakeTime;

  const NetworkPerformanceMetrics({
    required this.endpoint,
    required this.latency,
    required this.responseSize,
    required this.statusCode,
    required this.isSuccess,
    required this.timestamp,
    required this.httpMethod,
    this.connectionTime,
    this.dnsLookupTime,
    this.sslHandshakeTime,
  });

  bool get exceedsBudget => latency > PerformanceBudgets.apiCall;

  @override
  List<Object?> get props => [
        endpoint,
        latency,
        responseSize,
        statusCode,
        isSuccess,
        timestamp,
        httpMethod,
        connectionTime,
        dnsLookupTime,
        sslHandshakeTime,
      ];
}

/// Network failure analysis (Point 267)
class NetworkFailureAnalysis extends Equatable {
  final DateTime timeWindow;
  final int totalRequests;
  final int failedRequests;
  final double failureRate; // Percentage
  final Map<String, int> failuresByEndpoint;
  final Map<int, int> failuresByStatusCode;
  final Duration avgFailureLatency;

  const NetworkFailureAnalysis({
    required this.timeWindow,
    required this.totalRequests,
    required this.failedRequests,
    required this.failureRate,
    required this.failuresByEndpoint,
    required this.failuresByStatusCode,
    required this.avgFailureLatency,
  });

  @override
  List<Object?> get props => [
        timeWindow,
        totalRequests,
        failedRequests,
        failureRate,
        failuresByEndpoint,
        failuresByStatusCode,
        avgFailureLatency,
      ];
}

/// Battery usage metrics (Point 268)
class BatteryUsageMetrics extends Equatable {
  final double batteryDrainPerHour; // Percentage
  final Map<String, double> drainByFeature;
  final bool isCharging;
  final int batteryLevel; // 0-100
  final DateTime measuredAt;
  final Duration appUsageDuration;

  const BatteryUsageMetrics({
    required this.batteryDrainPerHour,
    required this.drainByFeature,
    required this.isCharging,
    required this.batteryLevel,
    required this.measuredAt,
    required this.appUsageDuration,
  });

  bool get isExcessiveDrain => batteryDrainPerHour > 10.0; // > 10% per hour

  @override
  List<Object?> get props => [
        batteryDrainPerHour,
        drainByFeature,
        isCharging,
        batteryLevel,
        measuredAt,
        appUsageDuration,
      ];
}

/// Memory usage metrics (Point 269)
class MemoryUsageMetrics extends Equatable {
  final int usedMemoryMB;
  final int totalMemoryMB;
  final double usagePercentage;
  final int heapSizeMB;
  final int externalMemoryMB;
  final bool hasMemoryLeak;
  final List<MemoryLeakIndicator>? leakIndicators;
  final DateTime measuredAt;

  const MemoryUsageMetrics({
    required this.usedMemoryMB,
    required this.totalMemoryMB,
    required this.usagePercentage,
    required this.heapSizeMB,
    required this.externalMemoryMB,
    required this.hasMemoryLeak,
    this.leakIndicators,
    required this.measuredAt,
  });

  bool get isHighUsage => usagePercentage > 80.0; // > 80% memory usage

  @override
  List<Object?> get props => [
        usedMemoryMB,
        totalMemoryMB,
        usagePercentage,
        heapSizeMB,
        externalMemoryMB,
        hasMemoryLeak,
        leakIndicators,
        measuredAt,
      ];
}

/// Memory leak indicator
class MemoryLeakIndicator extends Equatable {
  final String className;
  final int instanceCount;
  final int expectedCount;
  final String suspectedCause;

  const MemoryLeakIndicator({
    required this.className,
    required this.instanceCount,
    required this.expectedCount,
    required this.suspectedCause,
  });

  @override
  List<Object?> get props => [
        className,
        instanceCount,
        expectedCount,
        suspectedCause,
      ];
}

/// App size metrics (Point 270)
class AppSizeMetrics extends Equatable {
  final int apkSizeMB; // Android
  final int ipaSizeMB; // iOS
  final int downloadSizeMB;
  final int installSizeMB;
  final Map<String, int> sizeByComponent; // Assets, code, resources
  final bool exceedsSizeLimit; // 50MB limit
  final DateTime measuredAt;

  const AppSizeMetrics({
    required this.apkSizeMB,
    required this.ipaSizeMB,
    required this.downloadSizeMB,
    required this.installSizeMB,
    required this.sizeByComponent,
    required this.exceedsSizeLimit,
    required this.measuredAt,
  });

  static const int maxSizeMB = 50;

  @override
  List<Object?> get props => [
        apkSizeMB,
        ipaSizeMB,
        downloadSizeMB,
        installSizeMB,
        sizeByComponent,
        exceedsSizeLimit,
        measuredAt,
      ];
}

/// Performance dashboard summary (Point 261)
class PerformanceDashboard extends Equatable {
  final DateTime generatedAt;
  final AppPerformanceSummary appPerformance;
  final NetworkPerformanceSummary networkPerformance;
  final List<PerformanceIssue> criticalIssues;
  final Map<String, double> performanceScores; // 0-100

  const PerformanceDashboard({
    required this.generatedAt,
    required this.appPerformance,
    required this.networkPerformance,
    required this.criticalIssues,
    required this.performanceScores,
  });

  double get overallScore {
    if (performanceScores.isEmpty) return 0.0;
    return performanceScores.values.reduce((a, b) => a + b) /
        performanceScores.length;
  }

  @override
  List<Object?> get props => [
        generatedAt,
        appPerformance,
        networkPerformance,
        criticalIssues,
        performanceScores,
      ];
}

/// App performance summary
class AppPerformanceSummary extends Equatable {
  final Duration avgAppLaunchTime;
  final Duration avgScreenTransitionTime;
  final int crashCount;
  final int anrCount;
  final double crashFreeRate; // Percentage
  final MemoryUsageMetrics memoryUsage;
  final BatteryUsageMetrics? batteryUsage;

  const AppPerformanceSummary({
    required this.avgAppLaunchTime,
    required this.avgScreenTransitionTime,
    required this.crashCount,
    required this.anrCount,
    required this.crashFreeRate,
    required this.memoryUsage,
    this.batteryUsage,
  });

  @override
  List<Object?> get props => [
        avgAppLaunchTime,
        avgScreenTransitionTime,
        crashCount,
        anrCount,
        crashFreeRate,
        memoryUsage,
        batteryUsage,
      ];
}

/// Network performance summary
class NetworkPerformanceSummary extends Equatable {
  final Duration avgApiLatency;
  final double apiSuccessRate; // Percentage
  final int totalApiCalls;
  final int failedApiCalls;
  final Map<String, Duration> latencyByEndpoint;

  const NetworkPerformanceSummary({
    required this.avgApiLatency,
    required this.apiSuccessRate,
    required this.totalApiCalls,
    required this.failedApiCalls,
    required this.latencyByEndpoint,
  });

  @override
  List<Object?> get props => [
        avgApiLatency,
        apiSuccessRate,
        totalApiCalls,
        failedApiCalls,
        latencyByEndpoint,
      ];
}

/// Performance issue
class PerformanceIssue extends Equatable {
  final String issueId;
  final PerformanceIssueSeverity severity;
  final String title;
  final String description;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;
  final List<String> affectedUsers;
  final String? suggestedFix;

  const PerformanceIssue({
    required this.issueId,
    required this.severity,
    required this.title,
    required this.description,
    required this.detectedAt,
    required this.metadata,
    required this.affectedUsers,
    this.suggestedFix,
  });

  @override
  List<Object?> get props => [
        issueId,
        severity,
        title,
        description,
        detectedAt,
        metadata,
        affectedUsers,
        suggestedFix,
      ];
}

/// Performance issue severity
enum PerformanceIssueSeverity {
  critical,
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case PerformanceIssueSeverity.critical:
        return 'Critical';
      case PerformanceIssueSeverity.high:
        return 'High';
      case PerformanceIssueSeverity.medium:
        return 'Medium';
      case PerformanceIssueSeverity.low:
        return 'Low';
    }
  }
}
