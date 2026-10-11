import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../security/viewer_watermark.dart';

/// Full-screen, pinch-to-zoom gallery (swipe between photos).
///
/// The one viewer for user photos opened full screen (profile photos,
/// experience photos). Every photo carries the GreenGo mark
/// ([ViewerWatermark.zoomed]): the mark is shown ONLY here, never on
/// thumbnails or carousels (owner decision 2026-10-11).
class ZoomPhotoViewer extends StatefulWidget {
  const ZoomPhotoViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
  });
  final List<String> urls;
  final int initialIndex;

  static Future<void> open(BuildContext context, List<String> urls, int index) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ZoomPhotoViewer(urls: urls, initialIndex: index),
      ));

  @override
  State<ZoomPhotoViewer> createState() => _ZoomPhotoViewerState();
}

class _ZoomPhotoViewerState extends State<ZoomPhotoViewer> {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _page,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: ViewerWatermark.zoomed(
                child: CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.richGold),
                ),
                errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                    size: 48),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text('${_index + 1} / ${widget.urls.length}',
                  style: const TextStyle(color: Colors.white70)),
            ),
          ),
      ]),
    );
  }
}
