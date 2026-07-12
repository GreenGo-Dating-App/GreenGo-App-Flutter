import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// A compact in-tile photo carousel for the Apple-safe people grids.
///
/// Shows one of the user's photos filling its box; when the user has more than
/// one photo, small semi-transparent ◀ ▶ arrow buttons are overlaid on the left
/// and right edges to cycle through them (wrap-around) without leaving the grid.
///
/// TWO independent tap targets:
///  - Tapping the PHOTO area (anywhere that is not an arrow) calls [onPhotoTap]
///    — the grids wire this to "open the chat immediately".
///  - Tapping an arrow only advances the internal index; because the arrows sit
///    ABOVE the photo in the [Stack] and consume the gesture, they never trigger
///    [onPhotoTap].
///
/// When [photoUrls] is empty (or a photo fails to load) it falls back to a
/// flag-tinted gradient with a large centered initial — no network image.
///
/// Reduced-motion safe: photos swap instantly, there is no implicit animation.
/// Sized to fill its parent, so it stays compact inside a 3-column grid tile.
class UserPhotoCarousel extends StatefulWidget {
  const UserPhotoCarousel({
    required this.photoUrls,
    required this.onPhotoTap,
    this.fallbackInitial,
    this.fallbackGradient,
    this.radius,
    super.key,
  });

  /// The user's photos, in order. May be empty (falls back to a gradient).
  final List<String> photoUrls;

  /// Called when the photo area (not an arrow) is tapped.
  final VoidCallback onPhotoTap;

  /// Large centered letter shown on the gradient fallback.
  final String? fallbackInitial;

  /// Gradient colours for the fallback fill (flag-tinted at the call site).
  final List<Color>? fallbackGradient;

  /// Optional clip radius applied to the whole carousel.
  final BorderRadius? radius;

  @override
  State<UserPhotoCarousel> createState() => _UserPhotoCarouselState();
}

class _UserPhotoCarouselState extends State<UserPhotoCarousel> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant UserPhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the index valid if the photo list shrinks (e.g. recycled tile).
    if (_index >= widget.photoUrls.length) _index = 0;
  }

  void _prev() {
    final n = widget.photoUrls.length;
    if (n < 2) return;
    setState(() => _index = (_index - 1 + n) % n);
  }

  void _next() {
    final n = widget.photoUrls.length;
    if (n < 2) return;
    setState(() => _index = (_index + 1) % n);
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photoUrls;
    final hasPhotos = photos.isNotEmpty;
    final safeIndex = hasPhotos ? _index.clamp(0, photos.length - 1) : 0;
    final fallback = _fallback();

    Widget content;
    if (hasPhotos) {
      content = Image.network(
        photos[safeIndex],
        key: ValueKey<String>(photos[safeIndex]),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      );
    } else {
      content = fallback;
    }

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        // Photo area — the primary tap target (opens the chat at the call site).
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPhotoTap,
            child: content,
          ),
        ),
        // Arrows only when there is more than one photo. They sit above the
        // photo and consume the tap, so they never trigger onPhotoTap.
        if (photos.length > 1) ...[
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ArrowButton(
                icon: Icons.chevron_left,
                onTap: _prev,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ArrowButton(
                icon: Icons.chevron_right,
                onTap: _next,
              ),
            ),
          ),
        ],
      ],
    );

    final radius = widget.radius;
    if (radius != null) {
      return ClipRRect(borderRadius: radius, child: stack);
    }
    return stack;
  }

  Widget _fallback() {
    final colors = widget.fallbackGradient ??
        const [AppColors.charcoal, AppColors.backgroundDark];
    final initial = (widget.fallbackInitial != null &&
            widget.fallbackInitial!.isNotEmpty)
        ? widget.fallbackInitial!.characters.first.toUpperCase()
        : '?';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.pureWhite.withValues(alpha: 0.9),
            fontSize: 48,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// A small semi-transparent circular arrow overlaid on the photo. A real tap
/// target that advances the carousel without opening the chat.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.deepBlack.withValues(alpha: 0.42),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.pureWhite.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.pureWhite.withValues(alpha: 0.95),
            size: 18,
          ),
        ),
      ),
    );
  }
}
