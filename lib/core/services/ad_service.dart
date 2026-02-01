import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/membership/domain/entities/membership.dart';

/// Service to manage advertisements in the app
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  // Counters for tracking when to show interstitial ads
  int _swipeCount = 0;
  int _messageCount = 0;

  // Current membership rules
  MembershipRules _rules = MembershipRules.freeDefaults;

  // Test Ad Unit IDs (replace with real ones for production)
  static const String _testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerAdUnitIdIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialAdUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910';

  // Production Ad Unit IDs (set these in your environment config)
  // TODO: Replace with your actual Ad Unit IDs
  static const String _prodBannerAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodBannerAdUnitIdIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodInterstitialAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodInterstitialAdUnitIdIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  /// Get the banner ad unit ID based on platform and debug mode
  String get _bannerAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? _testBannerAdUnitIdIOS
          : _testBannerAdUnitIdAndroid;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _prodBannerAdUnitIdIOS
        : _prodBannerAdUnitIdAndroid;
  }

  /// Get the interstitial ad unit ID based on platform and debug mode
  String get _interstitialAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? _testInterstitialAdUnitIdIOS
          : _testInterstitialAdUnitIdAndroid;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _prodInterstitialAdUnitIdIOS
        : _prodInterstitialAdUnitIdAndroid;
  }

  /// Initialize the ad service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;

      // Load counters from local storage
      await _loadCounters();

      debugPrint('AdService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AdService: $e');
    }
  }

  /// Update the membership rules for ad display logic
  void updateMembershipRules(MembershipRules rules) {
    _rules = rules;

    // If ads are disabled, dispose all loaded ads
    if (!_rules.showAds) {
      disposeBannerAd();
      disposeInterstitialAd();
    }
  }

  /// Check if ads should be shown based on current membership
  bool get shouldShowAds => _rules.showAds;

  /// Check if banner ads should be shown
  bool get shouldShowBannerAds => _rules.showAds && _rules.showBannerAds;

  /// Load counters from shared preferences
  Future<void> _loadCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayKey();
      final savedDate = prefs.getString('ad_counter_date');

      if (savedDate == today) {
        _swipeCount = prefs.getInt('ad_swipe_count') ?? 0;
        _messageCount = prefs.getInt('ad_message_count') ?? 0;
      } else {
        // Reset counters for new day
        _swipeCount = 0;
        _messageCount = 0;
        await _saveCounters();
      }
    } catch (e) {
      debugPrint('Failed to load ad counters: $e');
    }
  }

  /// Save counters to shared preferences
  Future<void> _saveCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ad_counter_date', _getTodayKey());
      await prefs.setInt('ad_swipe_count', _swipeCount);
      await prefs.setInt('ad_message_count', _messageCount);
    } catch (e) {
      debugPrint('Failed to save ad counters: $e');
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ==================== Banner Ads ====================

  /// Load a banner ad
  Future<BannerAd?> loadBannerAd({
    AdSize size = AdSize.banner,
    Function()? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!shouldShowBannerAds || !_isInitialized) {
      return null;
    }

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          onAdFailedToLoad?.call(error);
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
    );

    await _bannerAd!.load();
    return _bannerAd;
  }

  /// Get the currently loaded banner ad
  BannerAd? get bannerAd => _bannerAd;

  /// Dispose the banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ==================== Interstitial Ads ====================

  /// Load an interstitial ad
  Future<void> loadInterstitialAd() async {
    if (!shouldShowAds || !_isInitialized) {
      return;
    }

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded');
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              // Pre-load next interstitial
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Record a swipe and potentially show an interstitial ad
  /// Returns true if an ad was shown
  Future<bool> recordSwipe() async {
    if (!shouldShowAds || _rules.swipesBeforeAd <= 0) {
      return false;
    }

    _swipeCount++;
    await _saveCounters();

    if (_swipeCount % _rules.swipesBeforeAd == 0) {
      return await showInterstitialAd();
    }

    return false;
  }

  /// Record a message and potentially show an interstitial ad
  /// Returns true if an ad was shown
  Future<bool> recordMessage() async {
    if (!shouldShowAds || _rules.messagesBeforeAd <= 0) {
      return false;
    }

    _messageCount++;
    await _saveCounters();

    if (_messageCount % _rules.messagesBeforeAd == 0) {
      return await showInterstitialAd();
    }

    return false;
  }

  /// Show the interstitial ad if loaded
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      return true;
    } else {
      // Try to load one for next time
      loadInterstitialAd();
      return false;
    }
  }

  /// Dispose the interstitial ad
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  // ==================== Cleanup ====================

  /// Dispose all ads and reset state
  void dispose() {
    disposeBannerAd();
    disposeInterstitialAd();
  }

  /// Get current swipe count (for debugging/display)
  int get swipeCount => _swipeCount;

  /// Get current message count (for debugging/display)
  int get messageCount => _messageCount;

  /// Get swipes until next ad
  int get swipesUntilAd {
    if (!shouldShowAds || _rules.swipesBeforeAd <= 0) return -1;
    return _rules.swipesBeforeAd - (_swipeCount % _rules.swipesBeforeAd);
  }

  /// Get messages until next ad
  int get messagesUntilAd {
    if (!shouldShowAds || _rules.messagesBeforeAd <= 0) return -1;
    return _rules.messagesBeforeAd - (_messageCount % _rules.messagesBeforeAd);
  }
}
