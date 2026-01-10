/// Version Config Setup Script
///
/// Run this script ONCE to initialize the Firestore version configuration document.
/// After initial setup, manage versions through Firebase Console or Admin SDK.
///
/// Usage:
///   1. Import this file in your main.dart temporarily
///   2. Call `await setupVersionConfig();` after Firebase.initializeApp()
///   3. Remove the call after first run
///
/// Or run from Firebase Console > Firestore > Create Document manually

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Initialize the version configuration document in Firestore
///
/// Document structure:
/// ```
/// app_config/version
/// {
///   maintenanceMode: false,
///   maintenanceMessage: "...",
///   android: { minVersion, recommendedVersion, currentVersion, storeUrl, releaseNotes },
///   ios: { minVersion, recommendedVersion, currentVersion, storeUrl, releaseNotes }
/// }
/// ```
Future<void> setupVersionConfig() async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.doc('app_config/version');

  // Check if document already exists
  final existingDoc = await docRef.get();
  if (existingDoc.exists) {
    debugPrint('⚠️ Version config already exists. Skipping setup.');
    debugPrint('   To update, use Firebase Console or updateVersionConfig()');
    return;
  }

  // Initial version configuration
  final versionConfig = {
    // Global settings
    'maintenanceMode': false,
    'maintenanceMessage':
        'We are currently performing scheduled maintenance to improve your experience. Please check back in a few minutes.',

    // Android configuration
    'android': {
      'minVersion': '1.0.0', // Force update if below this
      'recommendedVersion': '1.0.0', // Soft update if below this
      'currentVersion': '1.0.0', // Latest available version
      'storeUrl':
          'https://play.google.com/store/apps/details?id=com.greengo.chat',
      'releaseNotes': 'Initial release with all core features.',
      'releaseDate': DateTime.now().toIso8601String(),
    },

    // iOS configuration
    'ios': {
      'minVersion': '1.0.0',
      'recommendedVersion': '1.0.0',
      'currentVersion': '1.0.0',
      'storeUrl': 'https://apps.apple.com/app/greengo/id123456789',
      'releaseNotes': 'Initial release with all core features.',
      'releaseDate': DateTime.now().toIso8601String(),
    },

    // Metadata
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': 'setup_script',
  };

  await docRef.set(versionConfig);
  debugPrint('✅ Version config created successfully!');
  debugPrint('   Path: app_config/version');
}

/// Update version configuration for a new release
///
/// Call this when deploying a new app version to the stores.
///
/// Example usage:
/// ```dart
/// await updateVersionConfig(
///   platform: 'android',
///   currentVersion: '1.1.0',
///   releaseNotes: 'New chat features and bug fixes',
///   isMajorUpdate: false, // true = force update for all older versions
/// );
/// ```
Future<void> updateVersionConfig({
  required String platform, // 'android' or 'ios'
  required String currentVersion,
  required String releaseNotes,
  bool isMajorUpdate = false,
  String? minVersion, // Override minimum version (force update threshold)
}) async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.doc('app_config/version');

  final updates = <String, dynamic>{
    '$platform.currentVersion': currentVersion,
    '$platform.recommendedVersion': currentVersion,
    '$platform.releaseNotes': releaseNotes,
    '$platform.releaseDate': DateTime.now().toIso8601String(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': 'admin_update',
  };

  // If major update, set minVersion to force all users to update
  if (isMajorUpdate || minVersion != null) {
    updates['$platform.minVersion'] = minVersion ?? currentVersion;
  }

  await docRef.update(updates);
  debugPrint('✅ Version config updated for $platform');
  debugPrint('   Current: $currentVersion');
  debugPrint('   Major update: $isMajorUpdate');
}

/// Enable maintenance mode
///
/// Blocks all app usage and shows maintenance screen.
/// Use for critical updates or backend migrations.
Future<void> enableMaintenanceMode({
  required String message,
  Duration? estimatedDuration,
}) async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.doc('app_config/version');

  String fullMessage = message;
  if (estimatedDuration != null) {
    final hours = estimatedDuration.inHours;
    final minutes = estimatedDuration.inMinutes % 60;
    if (hours > 0) {
      fullMessage += '\n\nEstimated time: ${hours}h ${minutes}m';
    } else {
      fullMessage += '\n\nEstimated time: ${minutes} minutes';
    }
  }

  await docRef.update({
    'maintenanceMode': true,
    'maintenanceMessage': fullMessage,
    'maintenanceStartedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  debugPrint('🔧 Maintenance mode ENABLED');
}

/// Disable maintenance mode
///
/// Restores normal app operation.
Future<void> disableMaintenanceMode() async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.doc('app_config/version');

  await docRef.update({
    'maintenanceMode': false,
    'maintenanceEndedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  debugPrint('✅ Maintenance mode DISABLED');
}

/// Force update for specific version
///
/// Use when a critical security issue is found in older versions.
/// All users below the specified version will be forced to update.
Future<void> forceUpdateBelow({
  required String platform,
  required String minVersion,
  String? securityMessage,
}) async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.doc('app_config/version');

  String releaseNotes = securityMessage ??
      'This update includes critical security fixes. Please update immediately.';

  await docRef.update({
    '$platform.minVersion': minVersion,
    '$platform.releaseNotes': releaseNotes,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': 'security_update',
  });

  debugPrint('🔒 Force update set for $platform < $minVersion');
}

/// Get current version configuration
///
/// Useful for debugging and admin dashboards.
Future<Map<String, dynamic>?> getVersionConfig() async {
  final firestore = FirebaseFirestore.instance;
  final docRef = firestore.doc('app_config/version');
  final snapshot = await docRef.get();

  if (snapshot.exists) {
    return snapshot.data();
  }
  return null;
}

/// Print current version configuration
Future<void> printVersionConfig() async {
  final config = await getVersionConfig();
  if (config == null) {
    debugPrint('❌ No version config found');
    return;
  }

  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('📱 VERSION CONFIGURATION');
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('Maintenance Mode: ${config['maintenanceMode']}');
  debugPrint('');
  debugPrint('ANDROID:');
  final android = config['android'] as Map<String, dynamic>?;
  if (android != null) {
    debugPrint('  Min Version: ${android['minVersion']}');
    debugPrint('  Recommended: ${android['recommendedVersion']}');
    debugPrint('  Current: ${android['currentVersion']}');
    debugPrint('  Store URL: ${android['storeUrl']}');
  }
  debugPrint('');
  debugPrint('iOS:');
  final ios = config['ios'] as Map<String, dynamic>?;
  if (ios != null) {
    debugPrint('  Min Version: ${ios['minVersion']}');
    debugPrint('  Recommended: ${ios['recommendedVersion']}');
    debugPrint('  Current: ${ios['currentVersion']}');
    debugPrint('  Store URL: ${ios['storeUrl']}');
  }
  debugPrint('═══════════════════════════════════════════════════════');
}
