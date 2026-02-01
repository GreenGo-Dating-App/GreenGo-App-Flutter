import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../constants/app_colors.dart';

/// A widget that displays a banner ad at the bottom of the screen
/// Shows a placeholder when ads are not configured or fail to load
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final bool showPlaceholder;

  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.showPlaceholder = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdService _adService = AdService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _adLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!_adService.shouldShowBannerAds) {
      setState(() {
        _adLoadFailed = true;
      });
      return;
    }

    try {
      _bannerAd = await _adService.loadBannerAd(
        size: widget.adSize,
        onAdLoaded: () {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _adLoadFailed = false;
            });
          }
        },
        onAdFailedToLoad: (error) {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _adLoadFailed = true;
            });
            debugPrint('Banner ad failed to load: ${error.message}');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _adLoadFailed = true;
        });
      }
      debugPrint('Exception loading banner ad: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ads are disabled for this tier, don't show anything
    if (!_adService.shouldShowBannerAds) {
      return const SizedBox.shrink();
    }

    // If ad loaded successfully, show the real ad
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Show placeholder if ad failed to load or is still loading
    if (widget.showPlaceholder) {
      return _buildPlaceholder();
    }

    return const SizedBox.shrink();
  }

  Widget _buildPlaceholder() {
    // Standard banner size is 320x50
    final width = widget.adSize.width > 0 ? widget.adSize.width.toDouble() : 320.0;
    final height = widget.adSize.height > 0 ? widget.adSize.height.toDouble() : 50.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.8),
            AppColors.richGold.withValues(alpha: 0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: Colors.white.withValues(alpha: 0.9),
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'GreenGo Premium - Ad Free',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'UPGRADE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A wrapper widget that adds a banner ad at the bottom of its child
class WithBannerAd extends StatelessWidget {
  final Widget child;
  final AdSize adSize;
  final bool showPlaceholder;

  const WithBannerAd({
    super.key,
    required this.child,
    this.adSize = AdSize.banner,
    this.showPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    final adService = AdService();

    if (!adService.shouldShowBannerAds) {
      return child;
    }

    return Column(
      children: [
        Expanded(child: child),
        BannerAdWidget(
          adSize: adSize,
          showPlaceholder: showPlaceholder,
        ),
      ],
    );
  }
}
