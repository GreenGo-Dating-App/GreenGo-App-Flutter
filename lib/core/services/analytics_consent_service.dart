import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'consent_recorder.dart';

/// The user's choice about analytics + crash reporting (Firebase Analytics,
/// Crashlytics, Performance Monitoring).
enum AnalyticsConsentChoice { unset, granted, denied }

/// Turns collection on/off in the Firebase SDKs. Abstracted for tests.
abstract class AnalyticsCollectionApplier {
  Future<void> apply({required bool enabled, required bool everEnabled});
}

class FirebaseAnalyticsCollectionApplier implements AnalyticsCollectionApplier {
  const FirebaseAnalyticsCollectionApplier();

  @override
  Future<void> apply({required bool enabled, required bool everEnabled}) async {
    // On WEB any FirebaseAnalytics method call initialises the JS SDK, which
    // immediately sends a page_view. So on web we never touch Analytics until
    // the user has allowed it (disabling something never started is a no-op).
    if (!kIsWeb || enabled || everEnabled) {
      try {
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
      } catch (e) {
        debugPrint('AnalyticsConsent: analytics toggle failed: $e');
      }
    }
    if (!kIsWeb) {
      // Crashlytics has no web implementation.
      try {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
        if (!enabled) {
          // Reports cached while collection was off are never sent.
          await FirebaseCrashlytics.instance.deleteUnsentReports();
        }
      } catch (e) {
        debugPrint('AnalyticsConsent: crashlytics toggle failed: $e');
      }
    }
    if (!kIsWeb || enabled || everEnabled) {
      try {
        await FirebasePerformance.instance.setPerformanceCollectionEnabled(enabled);
      } catch (e) {
        debugPrint('AnalyticsConsent: performance toggle failed: $e');
      }
    }
  }
}

/// Analytics / crash-reporting consent (ePrivacy art. 5(3), GDPR, UK PECR).
///
/// * Consent-required regions (EEA, UK, Switzerland, and any device whose
///   region is unknown): collection is OFF until the user accepts.
/// * Elsewhere: collection is ON by default (previous behaviour) and the user
///   may switch it off in Privacy settings.
///
/// The region is decided ONCE on first run from the device locale and stored,
/// so travelling does not flip the default. The choice is stored locally and,
/// when signed in, recorded server-side (`recordConsent`, type `analytics`).
///
/// Every analytics / crash call in the app must check [collectionAllowed]
/// (synchronous) first. Native auto-collection is disabled in the Android
/// manifest / iOS Info.plist and switched on at startup by [applyAtStartup]
/// only when allowed.
class AnalyticsConsentService {
  AnalyticsConsentService({
    AnalyticsCollectionApplier? applier,
    String? Function()? deviceCountryCode,
    ConsentRecorder? recorder,
  })  : _applier = applier ?? const FirebaseAnalyticsCollectionApplier(),
        _deviceCountryCode = deviceCountryCode ??
            (() => PlatformDispatcher.instance.locale.countryCode),
        _recorder = recorder;

  static AnalyticsConsentService instance = AnalyticsConsentService();

  /// Bump when the notice text changes materially.
  static const int currentVersion = 1;

  static const String prefsChoiceKey = 'analytics_consent_choice_v1';
  static const String prefsRegionKey = 'analytics_consent_region_v1';
  static const String prefsEverEnabledKey = 'analytics_consent_ever_enabled_v1';

  /// EEA (EU 27 + IS, LI, NO), United Kingdom, Switzerland.
  static const Set<String> consentRequiredCountries = {
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR',
    'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK',
    'SI', 'ES', 'SE', // EU 27
    'IS', 'LI', 'NO', // EEA
    'GB', 'UK', // United Kingdom (ISO is GB; some devices report UK)
    'CH', // Switzerland
    'GF', 'GP', 'MQ', 'RE', 'YT', 'MF', // EU outermost regions (FR)
  };

  /// True when [countryCode] needs prior consent. Unknown => true (safe side).
  static bool isConsentRequiredRegion(String? countryCode) {
    if (countryCode == null || countryCode.trim().isEmpty) return true;
    return consentRequiredCountries.contains(countryCode.trim().toUpperCase());
  }

  final AnalyticsCollectionApplier _applier;
  final String? Function() _deviceCountryCode;
  final ConsentRecorder? _recorder;

  SharedPreferences? _prefs;
  bool _consentRequired = true;
  String? _region;
  bool _everEnabled = false;

  /// Notifies when the choice changes (settings toggle, prompt).
  final ValueNotifier<AnalyticsConsentChoice> choice =
      ValueNotifier(AnalyticsConsentChoice.unset);

  bool get initialized => _prefs != null;
  bool get consentRequired => _consentRequired;
  String? get region => _region;

  /// Whether analytics / crash data may be collected right now. False until
  /// [init] ran (nothing is collected before we know).
  bool get collectionAllowed {
    if (!initialized) return false;
    if (kIsWeb && choice.value != AnalyticsConsentChoice.granted) return false;
    switch (choice.value) {
      case AnalyticsConsentChoice.granted:
        return true;
      case AnalyticsConsentChoice.denied:
        return false;
      case AnalyticsConsentChoice.unset:
        return !_consentRequired;
    }
  }

  /// Show the first-run prompt? Only in consent-required regions, until the
  /// user decides.
  bool get shouldPrompt =>
      initialized && _consentRequired && choice.value == AnalyticsConsentChoice.unset;

  /// Loads the stored choice / region (deciding the region on first run).
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    var stored = prefs.getString(prefsRegionKey);
    if (stored == null) {
      final cc = _deviceCountryCode();
      stored = (cc == null || cc.isEmpty) ? '??' : cc.toUpperCase();
      try {
        await prefs.setString(prefsRegionKey, stored);
      } catch (_) {}
    }
    _region = stored;
    _consentRequired = isConsentRequiredRegion(stored == '??' ? null : stored);
    _everEnabled = prefs.getBool(prefsEverEnabledKey) ?? false;
    switch (prefs.getString(prefsChoiceKey)) {
      case 'granted':
        choice.value = AnalyticsConsentChoice.granted;
      case 'denied':
        choice.value = AnalyticsConsentChoice.denied;
      default:
        choice.value = AnalyticsConsentChoice.unset;
    }
  }

  /// Applies the current state to the SDKs. Call once at startup after [init].
  Future<void> applyAtStartup() => _apply();

  Future<void> _apply() async {
    // Web never ran Analytics before this change (no Dart call initialised the
    // JS SDK), so on web collection starts ONLY on an explicit "allow",
    // whatever the region. Mobile keeps its previous default outside
    // consent-required regions.
    final enabled = kIsWeb
        ? choice.value == AnalyticsConsentChoice.granted
        : collectionAllowed;
    if (enabled && !_everEnabled) {
      _everEnabled = true;
      try {
        await _prefs?.setBool(prefsEverEnabledKey, true);
      } catch (_) {}
    }
    await _applier.apply(enabled: enabled, everEnabled: _everEnabled);
  }

  /// The user's decision (prompt or settings toggle).
  Future<void> setChoice({required bool granted, bool recordOnServer = true}) async {
    choice.value =
        granted ? AnalyticsConsentChoice.granted : AnalyticsConsentChoice.denied;
    try {
      await _prefs?.setString(prefsChoiceKey, granted ? 'granted' : 'denied');
    } catch (_) {}
    await _apply();
    if (recordOnServer) {
      unawaited((_recorder ?? ConsentRecorder.instance).record(
        type: ConsentTypes.analytics,
        accepted: granted,
        version: currentVersion,
        region: _region,
      ));
    }
  }
}
