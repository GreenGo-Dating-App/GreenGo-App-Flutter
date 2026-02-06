import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

/// Cached Profile Image Widget
///
/// A reusable widget for displaying profile images with caching support.
/// Uses cached_network_image package for efficient image caching.
class CachedProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedProfileImage({
    super.key,
    this.imageUrl,
    this.size = 100,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _buildPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        memCacheWidth: (size * 2).toInt(), // Cache at 2x for retina displays
        memCacheHeight: (size * 2).toInt(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.richGold,
          ),
        ),
      ),
    );
  }
}

/// Circular variant of CachedProfileImage
class CachedProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => placeholder ?? _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheWidth: (radius * 4).toInt(),
      memCacheHeight: (radius * 4).toInt(),
    );
  }

  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.backgroundCard,
      child: Icon(
        Icons.person,
        size: radius,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.backgroundCard,
      child: SizedBox(
        width: radius,
        height: radius,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.richGold,
        ),
      ),
    );
  }
}
