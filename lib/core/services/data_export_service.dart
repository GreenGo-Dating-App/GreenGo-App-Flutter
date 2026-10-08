import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Why a data export did not produce a link.
enum DataExportFailure {
  requiresRecentLogin,
  rateLimited,
  inProgress,
  network,
  failed
}

/// Result of [DataExportService.requestExport].
class DataExportResult {
  const DataExportResult.success(
      {required this.url, this.expiresAt, this.emailSent = false})
      : failure = null;
  const DataExportResult.failed(this.failure)
      : url = null,
        expiresAt = null,
        emailSent = false;

  final String? url;
  final DateTime? expiresAt;
  final bool emailSent;
  final DataExportFailure? failure;

  bool get ok => url != null;
}

/// "Download my data" (P3-2; GDPR Art. 15/20, LGPD Art. 18): calls the
/// `exportMyData` callable, which builds a ZIP of the caller's data and
/// returns a 24 h link (also emailed). Needs a sign-in from the last 10
/// minutes; one export per 24 h.
class DataExportService {
  DataExportService({Future<Map<String, dynamic>> Function()? call})
      : _call = call;

  static final DataExportService instance = DataExportService();

  final Future<Map<String, dynamic>> Function()? _call;

  Future<DataExportResult> requestExport() async {
    try {
      final data = await (_call ?? _callExportMyData)();
      final url = data['url'];
      if (data['success'] == true && url is String && url.isNotEmpty) {
        return DataExportResult.success(
          url: url,
          expiresAt: DateTime.tryParse('${data['expiresAt'] ?? ''}'),
          emailSent: data['emailSent'] == true,
        );
      }
      return const DataExportResult.failed(DataExportFailure.failed);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[DataExport] exportMyData failed: ${e.code}');
      return DataExportResult.failed(failureFor(e.code, e.details));
    } catch (e) {
      debugPrint('[DataExport] exportMyData failed: $e');
      return const DataExportResult.failed(DataExportFailure.failed);
    }
  }

  static Future<Map<String, dynamic>> _callExportMyData() async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('exportMyData',
            // Large accounts take a few minutes to package.
            options:
                HttpsCallableOptions(timeout: const Duration(seconds: 540)))
        .call<Map<String, dynamic>>(<String, dynamic>{});
    return Map<String, dynamic>.from(res.data);
  }

  /// Maps a callable error (code + `details.code`) to a [DataExportFailure].
  @visibleForTesting
  static DataExportFailure failureFor(String code, Object? details) {
    final detailCode =
        details is Map ? details['code'] ?? details['reason'] : null;
    switch (detailCode) {
      case 'REQUIRES_RECENT_LOGIN':
        return DataExportFailure.requiresRecentLogin;
      case 'RATE_LIMITED':
        return DataExportFailure.rateLimited;
      case 'EXPORT_IN_PROGRESS':
        return DataExportFailure.inProgress;
    }
    if (code == 'unavailable' || code == 'deadline-exceeded')
      return DataExportFailure.network;
    return DataExportFailure.failed;
  }
}
