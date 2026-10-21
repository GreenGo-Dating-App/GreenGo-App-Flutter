import 'package:flutter/material.dart';

import '../media/cover_focus.dart';

/// Shows [image] in its frame with `BoxFit.cover` positioned at the user's
/// [focus] (focal point + zoom). Use it (or [FocalCoverImage.wrap] around an
/// image that already takes `alignment`) wherever a cover / main photo is
/// displayed, so every frame shows the part of the picture the user chose.
class FocalCoverImage extends StatelessWidget {
  const FocalCoverImage({
    super.key,
    required this.image,
    this.focus = CoverFocus.center,
    this.errorBuilder,
    this.width = double.infinity,
    this.height = double.infinity,
  });

  final ImageProvider image;
  final CoverFocus focus;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double width;
  final double height;

  /// Applies [focus]'s zoom about its focal point to [child], which must
  /// itself be a BoxFit.cover image aligned at `focus.alignment`.
  static Widget wrap(CoverFocus focus, Widget child) {
    if (focus.zoom <= 1) return child;
    return ClipRect(
      child: Transform.scale(
        scale: focus.zoom,
        alignment: focus.alignment,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = focus.clamped();
    return wrap(
      f,
      Image(
        image: image,
        fit: BoxFit.cover,
        alignment: f.alignment,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: errorBuilder,
      ),
    );
  }
}
