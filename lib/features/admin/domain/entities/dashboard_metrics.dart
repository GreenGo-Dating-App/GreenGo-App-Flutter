/**
 * Dashboard Metrics Entity
 * Points 228-234: Admin dashboard analytics
 */

import 'package:equatable/equatable.dart';

/// Real-time user activity metrics (Point 228)
class UserActivityMetrics extends Equatable {
  final int activeUsersNow; // Currently online
  final int activeUsersToday; // Active in last 24 hours
  final int activeUsersWeek; // Active in last 7 days
  final int activeUsersMonth; // Active in last 30 days
  final int newSignupsToday;
  final int newSignupsWeek;
  final int newSignupsMonth;
  final int deletedAccountsToday;
  final int deletedAccountsWeek;
  final int deletedAccountsMonth;
  final DateTime calculatedAt;

  const UserActivityMetrics({
    required this.activeUsersNow,
    required this.activeUsersToday,
    required this.activeUsersWeek,
    required this.activeUsersMonth,
    required this.newSignupsToday,
    required this.newSignupsWeek,
    required this.newSignupsMonth,
    required this.deletedAccountsToday,
    required this.deletedAccountsWeek,
    required this.deletedAccountsMonth,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [
        activeUsersNow,
        activeUsersToday,
        activeUsersWeek,
        activeUsersMonth,
        newSignupsToday,
        newSignupsWeek,
        newSignupsMonth,
        deletedAccountsToday,
        deletedAccountsWeek,
        deletedAccountsMonth,
        calculatedAt,
      ];
}

/// User growth chart data (Point 229)
class UserGrowthChart extends Equatable {
  final List<GrowthDataPoint> dailyData;
  final List<GrowthDataPoint> weeklyData;
  final List<GrowthDataPoint> monthlyData;
  final GrowthTrend trend;
  final double growthRate; // Percentage

  const UserGrowthChart({
    required this.dailyData,
    required this.weeklyData,
    required this.monthlyData,
    required this.trend,
    required this.growthRate,
  });

  @override
  List<Object?> get props => [
        dailyData,
        weeklyData,
        monthlyData,
        trend,
        growthRate,
      ];
}

/// Growth data point for charts
class GrowthDataPoint extends Equatable {
  final DateTime date;
  final int totalUsers;
  final int newSignups;
  final int deletedAccounts;
  final int netGrowth; // newSignups - deletedAccounts

  const GrowthDataPoint({
    required this.date,
    required this.totalUsers,
    required this.newSignups,
    required this.deletedAccounts,
    required this.netGrowth,
  });

  @override
  List<Object?> get props => [
        date,
        totalUsers,
        newSignups,
        deletedAccounts,
        netGrowth,
      ];
}

/// Growth trend
enum GrowthTrend {
  increasing,
  decreasing,
  stable,
  volatile,
}

/// Revenue metrics (Point 230)
class RevenueMetrics extends Equatable {
  final double todayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final double yearRevenue;
  final double mrr; // Monthly Recurring Revenue
  final double arr; // Annual Recurring Revenue
  final int activeSubscribers;
  final int newSubscribersToday;
  final int newSubscribersWeek;
  final int newSubscribersMonth;
  final int churnedSubscribersToday;
  final int churnedSubscribersWeek;
  final int churnedSubscribersMonth;
  final double churnRate; // Percentage
  final Map<String, double> revenueByTier; // Silver, Gold, Platinum
  final DateTime calculatedAt;

  const RevenueMetrics({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.yearRevenue,
    required this.mrr,
    required this.arr,
    required this.activeSubscribers,
    required this.newSubscribersToday,
    required this.newSubscribersWeek,
    required this.newSubscribersMonth,
    required this.churnedSubscribersToday,
    required this.churnedSubscribersWeek,
    required this.churnedSubscribersMonth,
    required this.churnRate,
    required this.revenueByTier,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [
        todayRevenue,
        weekRevenue,
        monthRevenue,
        yearRevenue,
        mrr,
        arr,
        activeSubscribers,
        newSubscribersToday,
        newSubscribersWeek,
        newSubscribersMonth,
        churnedSubscribersToday,
        churnedSubscribersWeek,
        churnedSubscribersMonth,
        churnRate,
        revenueByTier,
        calculatedAt,
      ];
}

/// Engagement metrics (Point 231)
class EngagementMetrics extends Equatable {
  final int totalMessages; // All-time
  final int messagesToday;
  final int messagesWeek;
  final int messagesMonth;
  final int totalMatches;
  final int matchesToday;
  final int matchesWeek;
  final int matchesMonth;
  final int totalLikes;
  final int likesToday;
  final int likesWeek;
  final int likesMonth;
  final double avgMessagesPerUser;
  final double avgMatchesPerUser;
  final double avgSessionDuration; // Minutes
  final double avgDailyActiveUsers;
  final double engagementRate; // Percentage
  final Map<String, int> featureUsage; // Super Likes, Boosts, etc.
  final DateTime calculatedAt;

  const EngagementMetrics({
    required this.totalMessages,
    required this.messagesToday,
    required this.messagesWeek,
    required this.messagesMonth,
    required this.totalMatches,
    required this.matchesToday,
    required this.matchesWeek,
    required this.matchesMonth,
    required this.totalLikes,
    required this.likesToday,
    required this.likesWeek,
    required this.likesMonth,
    required this.avgMessagesPerUser,
    required this.avgMatchesPerUser,
    required this.avgSessionDuration,
    required this.avgDailyActiveUsers,
    required this.engagementRate,
    required this.featureUsage,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [
        totalMessages,
        messagesToday,
        messagesWeek,
        messagesMonth,
        totalMatches,
        matchesToday,
        matchesWeek,
        matchesMonth,
        totalLikes,
        likesToday,
        likesWeek,
        likesMonth,
        avgMessagesPerUser,
        avgMatchesPerUser,
        avgSessionDuration,
        avgDailyActiveUsers,
        engagementRate,
        featureUsage,
        calculatedAt,
      ];
}

/// Geographic heatmap data (Point 232)
class GeographicHeatmap extends Equatable {
  final List<LocationData> locations;
  final String topCountry;
  final String topCity;
  final int totalCountries;
  final int totalCities;
  final DateTime calculatedAt;

  const GeographicHeatmap({
    required this.locations,
    required this.topCountry,
    required this.topCity,
    required this.totalCountries,
    required this.totalCities,
    required this.calculatedAt,
  });

  @override
  List<Object?> get props => [
        locations,
        topCountry,
        topCity,
        totalCountries,
        totalCities,
        calculatedAt,
      ];
}

/// Location data for heatmap
class LocationData extends Equatable {
  final String country;
  final String? city;
  final double latitude;
  final double longitude;
  final int userCount;
  final int activeUserCount;
  final double intensity; // 0-1 for heatmap visualization

  const LocationData({
    required this.country,
    this.city,
    required this.latitude,
    required this.longitude,
    required this.userCount,
    required this.activeUserCount,
    required this.intensity,
  });

  @override
  List<Object?> get props => [
        country,
        city,
        latitude,
        longitude,
        userCount,
        activeUserCount,
        intensity,
      ];
}

/// System health monitoring (Point 233)
class SystemHealthMetrics extends Equatable {
  final double apiResponseTime; // Milliseconds
  final double errorRate; // Percentage
  final double successRate; // Percentage
  final int totalRequests;
  final int failedRequests;
  final Map<String, EndpointHealth> endpointHealth;
  final List<SystemAlert> activeAlerts;
  final SystemStatus status;
  final DateTime calculatedAt;

  const SystemHealthMetrics({
    required this.apiResponseTime,
    required this.errorRate,
    required this.successRate,
    required this.totalRequests,
    required this.failedRequests,
    required this.endpointHealth,
    required this.activeAlerts,
    required this.status,
    required this.calculatedAt,
  });

  bool get isHealthy => status == SystemStatus.healthy;
  bool get hasCriticalAlerts =>
      activeAlerts.any((alert) => alert.severity == AlertSeverity.critical);

  @override
  List<Object?> get props => [
        apiResponseTime,
        errorRate,
        successRate,
        totalRequests,
        failedRequests,
        endpointHealth,
        activeAlerts,
        status,
        calculatedAt,
      ];
}

/// Endpoint health status
class EndpointHealth extends Equatable {
  final String endpoint;
  final double avgResponseTime;
  final double errorRate;
  final int requestCount;
  final HealthStatus status;

  const EndpointHealth({
    required this.endpoint,
    required this.avgResponseTime,
    required this.errorRate,
    required this.requestCount,
    required this.status,
  });

  @override
  List<Object?> get props => [
        endpoint,
        avgResponseTime,
        errorRate,
        requestCount,
        status,
      ];
}

/// Health status
enum HealthStatus {
  healthy,
  degraded,
  critical,
}

/// System status
enum SystemStatus {
  healthy,
  degraded,
  critical,
  maintenance,
}

/// System alert (Point 234)
class SystemAlert extends Equatable {
  final String alertId;
  final String title;
  final String description;
  final AlertType type;
  final AlertSeverity severity;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;
  final bool isResolved;
  final String? resolvedBy;
  final Map<String, dynamic> metadata;

  const SystemAlert({
    required this.alertId,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.triggeredAt,
    this.resolvedAt,
    required this.isResolved,
    this.resolvedBy,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        alertId,
        title,
        description,
        type,
        severity,
        triggeredAt,
        resolvedAt,
        isResolved,
        resolvedBy,
        metadata,
      ];
}

/// Alert types
enum AlertType {
  highErrorRate,
  slowResponseTime,
  highUserGrowth,
  lowUserGrowth,
  highChurnRate,
  revenueAnomaly,
  suspiciousActivity,
  systemOutage,
  apiQuotaExceeded,
  databaseOverload,
}

/// Alert severity
enum AlertSeverity {
  info,
  warning,
  critical,
}
