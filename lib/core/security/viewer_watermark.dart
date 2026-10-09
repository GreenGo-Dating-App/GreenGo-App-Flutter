import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

import '../services/own_profile_store.dart';

/// Whether a photo / media item gets the viewer watermark.
///
/// Private photos (private albums, chat media) are watermarked on every
/// platform; on web, where screenshots cannot be blocked at all, every photo
/// is. [isWeb] is only overridden by tests.
bool shouldWatermarkMedia({required bool isPrivate, bool? isWeb}) =>
    isPrivate || (isWeb ?? kIsWeb);

/// Text stamped over protected media: who is LOOKING at it (not who owns
/// it), so a leaked screenshot or phone photo of the screen can be traced
/// back to the account that leaked it. `@nickname · uid-prefix`.
String viewerWatermarkLabel({String? uid, String? nickname}) {
  final id = (uid ?? '').trim();
  final nick = (nickname ?? '').trim();
  final shortId = id.length > 10 ? id.substring(0, 10) : id;
  if (nick.isNotEmpty && shortId.isNotEmpty) return '@$nick · $shortId';
  if (nick.isNotEmpty) return '@$nick';
  return shortId;
}

/// Label for the signed-in viewer (empty when signed out / no Firebase).
String currentViewerWatermarkLabel() {
  String? uid;
  try {
    uid = FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    // Firebase not initialised (tests, previews).
  }
  if (uid == null || uid.isEmpty) return '';
  final profile = OwnProfileStore.instance.peek(uid);
  return viewerWatermarkLabel(
    uid: uid,
    nickname: profile?.nickname ?? profile?.displayName,
  );
}

/// Overlays a repeated, diagonal, semi-transparent [label] on [child].
///
/// Painted in the same layer as the image, so it is part of any screenshot,
/// screen recording or phone photo of the screen. It never takes input
/// ([IgnorePointer]) so zoom/pan/tap on the image keep working.
class ViewerWatermark extends StatelessWidget {
  const ViewerWatermark({
    required this.child,
    super.key,
    this.label,
    this.enabled = true,
    this.opacity = 0.16,
  });

  /// Convenience: watermark only when [shouldWatermarkMedia] says so.
  factory ViewerWatermark.media({
    required Widget child,
    required bool isPrivate,
    Key? key,
    String? label,
  }) =>
      ViewerWatermark(
        key: key,
        label: label,
        enabled: shouldWatermarkMedia(isPrivate: isPrivate),
        child: child,
      );

  final Widget child;

  /// Defaults to [currentViewerWatermarkLabel].
  final String? label;
  final bool enabled;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final text = label ?? currentViewerWatermarkLabel();
    if (text.isEmpty) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: CustomPaint(
                key: const ValueKey('viewerWatermark'),
                painter: WatermarkPainter(text: text, opacity: opacity),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tiles [text] at -30 degrees across the whole area.
@visibleForTesting
class WatermarkPainter extends CustomPainter {
  WatermarkPainter({required this.text, required this.opacity});

  final String text;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final fontSize = (size.shortestSide / 22).clamp(10.0, 18.0);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: opacity),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final stepX = tp.width + fontSize * 4;
    final stepY = fontSize * 6;
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-math.pi / 6);
    var row = 0;
    for (var y = -diagonal / 2; y < diagonal / 2; y += stepY, row++) {
      final offset = row.isEven ? 0.0 : stepX / 2;
      for (var x = -diagonal / 2 - offset; x < diagonal / 2; x += stepX) {
        tp.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) =>
      oldDelegate.text != text || oldDelegate.opacity != opacity;
}
