import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Version Check Result
enum UpdateType {
  none,           // No update needed
  soft,           // Optional update available
  force,          // Mandatory update required
  maintenance,    // App is in maintenance mode
}

/// Version Configuration from Firestore
class VersionConfig {
  final String minVersion;
  final String recommendedVersion;
  final String currentVersion;
  final String storeUrl;
  final String releaseNotes;
  final DateTime releaseDate;

  const VersionConfig({
    required this.minVersion,
    required this.recommendedVersion,
    required this.currentVersion,
    required this.storeUrl,
    required this.releaseNotes,
    required this.releaseDate,
  });

  factory VersionConfig.fromJson(Map<String, dynamic> json) {
    return VersionConfig(
      minVersion: json['minVersion'] as String? ?? '1.0.0',
      recommendedVersion: json['recommendedVersion'] as String? ?? '1.0.0',
      currentVersion: json['currentVersion'] as String? ?? '1.0.0',
      storeUrl: json['storeUrl'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      releaseDate: json['releaseDate'] != null
          ? DateTime.tryParse(json['releaseDate'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Default configuration
  static VersionConfig get defaultConfig => VersionConfig(
    minVersion: '1.0.0',
    recommendedVersion: '1.0.0',
    currentVersion: '1.0.0',
    storeUrl: '',
    releaseNotes: '',
    releaseDate: DateTime.now(),
  );
}

/// App Version Check Result
class VersionCheckResult {
  final UpdateType updateType;
  final String? storeUrl;
  final String? releaseNotes;
  final String? maintenanceMessage;
  final String installedVersion;
  final String? requiredVersion;

  const VersionCheckResult({
    required this.updateType,
    this.storeUrl,
    this.releaseNotes,
    this.maintenanceMessage,
    required this.installedVersion,
    this.requiredVersion,
  });
}

/// Version Check Service
///
/// Checks app version against Firestore configuration and determines
/// if a force update, soft update, or maintenance mode is required.
class VersionCheckService extends ChangeNotifier {
  static final VersionCheckService _instance = VersionCheckService._internal();
  factory VersionCheckService() => _instance;
  VersionCheckService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _subscription;

  // Cached values
  bool _maintenanceMode = false;
  String _maintenanceMessage = '';
  VersionConfig? _androidConfig;
  VersionConfig? _iosConfig;
  String _installedVersion = '1.0.0';
  bool _isInitialized = false;
  bool _softUpdateDismissed = false;

  // Getters
  bool get maintenanceMode => _maintenanceMode;
  String get maintenanceMessage => _maintenanceMessage;
  bool get isInitialized => _isInitialized;
  String get installedVersion => _installedVersion;

  /// Initialize the service and start listening for updates
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get installed app version
      final packageInfo = await PackageInfo.fromPlatform();
      _installedVersion = packageInfo.version;
      debugPrint('📱 Installed app version: $_installedVersion');

      // Load version config from Firestore
      final docRef = _firestore.doc('app_config/version');
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        _updateConfig(docSnap);
      }

      _isInitialized = true;

      // Start listening for real-time updates
      _subscription = docRef.snapshots().listen(
        (snapshot) {
          if (snapshot.exists) {
            _updateConfig(snapshot);
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Version config stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing version check service: $e');
      _isInitialized = true; // Continue without blocking
    }
  }

  void _updateConfig(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    _maintenanceMode = data['maintenanceMode'] as bool? ?? false;
    _maintenanceMessage = data['maintenanceMessage'] as String? ??
        'We are currently performing maintenance. Please try again later.';

    final androidData = data['android'] as Map<String, dynamic>?;
    final iosData = data['ios'] as Map<String, dynamic>?;

    if (androidData != null) {
      _androidConfig = VersionConfig.fromJson(androidData);
    }
    if (iosData != null) {
      _iosConfig = VersionConfig.fromJson(iosData);
    }

    debugPrint('📱 Version config updated - Maintenance: $_maintenanceMode');
  }

  /// Get the appropriate version config for current platform
  VersionConfig get _platformConfig {
    if (Platform.isAndroid) {
      return _androidConfig ?? VersionConfig.defaultConfig;
    } else if (Platform.isIOS) {
      return _iosConfig ?? VersionConfig.defaultConfig;
    }
    return VersionConfig.defaultConfig;
  }

  /// Check if update is required
  VersionCheckResult checkVersion() {
    // Check maintenance mode first
    if (_maintenanceMode) {
      return VersionCheckResult(
        updateType: UpdateType.maintenance,
        maintenanceMessage: _maintenanceMessage,
        installedVersion: _installedVersion,
      );
    }

    final config = _platformConfig;

    // Check for force update
    if (_compareVersions(_installedVersion, config.minVersion) < 0) {
      return VersionCheckResult(
        updateType: UpdateType.force,
        storeUrl: config.storeUrl,
        releaseNotes: config.releaseNotes,
        installedVersion: _installedVersion,
        requiredVersion: config.minVersion,
      );
    }

    // Check for soft update (only if not dismissed)
    if (!_softUpdateDismissed &&
        _compareVersions(_installedVersion, config.recommendedVersion) < 0) {
      return VersionCheckResult(
        updateType: UpdateType.soft,
        storeUrl: config.storeUrl,
        releaseNotes: config.releaseNotes,
        installedVersion: _installedVersion,
        requiredVersion: config.recommendedVersion,
      );
    }

    // No update needed
    return VersionCheckResult(
      updateType: UpdateType.none,
      installedVersion: _installedVersion,
    );
  }

  /// Dismiss soft update prompt for this session
  void dismissSoftUpdate() {
    _softUpdateDismissed = true;
    notifyListeners();
  }

  /// Open store URL for update
  Future<bool> openStore() async {
    final config = _platformConfig;
    if (config.storeUrl.isEmpty) return false;

    final uri = Uri.parse(config.storeUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Compare semantic versions
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Global instance for easy access
final versionCheck = VersionCheckService();
