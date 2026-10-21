import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../media/cover_focus.dart';
import 'cover_image_size_hint.dart';
import 'focal_cover_image.dart';

/// How a preview frame shows the picture.
enum CoverFrameKind {
  /// Picture fills the frame, title over a bottom gradient (cards, headers).
  banner,

  /// Small square picture with the title next to it (list rows).
  thumbnail,

  /// Circle (logos / avatars), title next to it.
  circle,
}

/// One real place where the picture is shown, at its real logical size
/// (scaled down to the screen width in the preview, aspect kept).
class CoverPreviewFrame {
  const CoverPreviewFrame({
    required this.label,
    required this.width,
    required this.height,
    this.kind = CoverFrameKind.banner,
  });

  final String label;
  final double width;
  final double height;
  final CoverFrameKind kind;

  double get aspectRatio => width / height;
}

/// Opens the positioning step for a picked cover / main photo: the user drags
/// (and pinch- or slider-zooms) the picture inside the real frame and sees it
/// live in every place it is shown. Resolves to the chosen [CoverFocus], or
/// null when dismissed (callers then keep their current focus).
Future<CoverFocus?> showCoverPositioner(
  BuildContext context, {
  required ImageProvider image,
  required List<CoverPreviewFrame> frames,
  CoverFocus initial = CoverFocus.center,
  CoverImageSpec spec = CoverImageSpec.banner,
  String? title,
  XFile? file,
  Size? knownSize,
}) {
  return Navigator.of(context).push<CoverFocus>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => CoverPositionerScreen(
        image: image,
        frames: frames,
        initial: initial,
        spec: spec,
        title: title,
        file: file,
        knownSize: knownSize,
      ),
    ),
  );
}

class CoverPositionerScreen extends StatefulWidget {
  const CoverPositionerScreen({
    super.key,
    required this.image,
    required this.frames,
    this.initial = CoverFocus.center,
    this.spec = CoverImageSpec.banner,
    this.title,
    this.file,
    this.knownSize,
    this.imageSize,
  });

  final ImageProvider image;
  final List<CoverPreviewFrame> frames;
  final CoverFocus initial;
  final CoverImageSpec spec;

  /// The listing / community / business name overlaid on the previews.
  final String? title;

  /// For the small / odd-shape warning.
  final XFile? file;
  final Size? knownSize;

  /// Pixel size of [image] when already known (tests); else resolved.
  final Size? imageSize;

  /// Moves [focus] by a drag of [delta] logical px inside a [frame] showing an
  /// image of [image] pixels with BoxFit.cover + zoom about the focal point.
  /// Dragging the picture right reveals more of its left side (x decreases).
  /// An axis with nothing to reveal does not move.
  static CoverFocus applyDrag(
      CoverFocus focus, Offset delta, Size frame, Size image) {
    if (image.width <= 0 || image.height <= 0) return focus;
    final s = [frame.width / image.width, frame.height / image.height]
        .reduce((a, b) => a > b ? a : b);
    final totalX = image.width * s * focus.zoom - frame.width;
    final totalY = image.height * s * focus.zoom - frame.height;
    final dx = totalX > 0.5 ? -2 * delta.dx / totalX : 0.0;
    final dy = totalY > 0.5 ? -2 * delta.dy / totalY : 0.0;
    return focus.copyWith(x: focus.x + dx, y: focus.y + dy);
  }

  @override
  State<CoverPositionerScreen> createState() => _CoverPositionerScreenState();
}

class _CoverPositionerScreenState extends State<CoverPositionerScreen> {
  late CoverFocus _focus = widget.initial.clamped();
  Size? _imgSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double _startZoom = 1;

  @override
  void initState() {
    super.initState();
    _imgSize = widget.imageSize;
    if (_imgSize == null) _resolveSize();
  }

  void _resolveSize() {
    final stream = widget.image.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() => _imgSize =
          Size(info.image.width.toDouble(), info.image.height.toDouble()));
    }, onError: (_, __) {});
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails d) => _startZoom = _focus.zoom;

  void _onScaleUpdate(ScaleUpdateDetails d, Size frame) {
    var f = _focus;
    if (d.pointerCount > 1) f = f.copyWith(zoom: _startZoom * d.scale);
    final img = _imgSize;
    if (img != null) {
      f = CoverPositionerScreen.applyDrag(f, d.focalPointDelta, frame, img);
    }
    if (f != _focus) setState(() => _focus = f);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spec = widget.spec;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(l10n.coverPositionTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            key: const Key('cover_position_done'),
            onPressed: () => Navigator.of(context).pop(_focus),
            child: Text(l10n.coverPositionDone,
                style: const TextStyle(
                    color: AppColors.richGold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      // The frame sits OUTSIDE the scrolling list: a vertical drag on it must
      // move the picture, not scroll the page.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.coverPositionHelp,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.3)),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: spec.circular ? 200 : 520),
                    child: AspectRatio(
                      aspectRatio: spec.aspectRatio,
                      child: LayoutBuilder(builder: (context, c) {
                        final frame = Size(c.maxWidth, c.maxHeight);
                        final picture = Stack(fit: StackFit.expand, children: [
                          FocalCoverImage(image: widget.image, focus: _focus),
                          const IgnorePointer(child: _ThirdsGrid()),
                        ]);
                        return GestureDetector(
                          key: const Key('cover_position_frame'),
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: (d) => _onScaleUpdate(d, frame),
                          child: spec.circular
                              ? ClipOval(child: picture)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: picture),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.zoom_out, color: AppColors.textTertiary),
                    Expanded(
                      child: Slider(
                        key: const Key('cover_position_zoom'),
                        value: _focus.zoom,
                        min: 1,
                        max: CoverFocus.maxZoom,
                        activeColor: AppColors.richGold,
                        onChanged: (v) =>
                            setState(() => _focus = _focus.copyWith(zoom: v)),
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: AppColors.textTertiary),
                    TextButton(
                      key: const Key('cover_position_reset'),
                      onPressed: () =>
                          setState(() => _focus = CoverFocus.center),
                      child: Text(l10n.coverPositionReset,
                          style: const TextStyle(color: AppColors.richGold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                CoverImageSizeHint(spec: spec),
                CoverImagePickWarning(
                  file: widget.file,
                  knownSize: widget.knownSize,
                  spec: spec,
                  showPreview: false,
                ),
                if (widget.frames.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(l10n.coverImageWarnPreview,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < widget.frames.length; i++)
                    _FramePreview(
                      key: Key('cover_preview_frame_$i'),
                      frame: widget.frames[i],
                      image: widget.image,
                      focus: _focus,
                      title: widget.title,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FramePreview extends StatelessWidget {
  const _FramePreview({
    super.key,
    required this.frame,
    required this.image,
    required this.focus,
    this.title,
  });

  final CoverPreviewFrame frame;
  final ImageProvider image;
  final CoverFocus focus;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final name = (title ?? '').trim();
    final pic = FocalCoverImage(image: image, focus: focus);
    Widget body;
    switch (frame.kind) {
      case CoverFrameKind.banner:
        body = LayoutBuilder(builder: (context, c) {
          final w = frame.width < c.maxWidth ? frame.width : c.maxWidth;
          return SizedBox(
            width: w,
            height: w / frame.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(fit: StackFit.expand, children: [
                pic,
                if (name.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                  ),
              ]),
            ),
          );
        });
        break;
      case CoverFrameKind.thumbnail:
      case CoverFrameKind.circle:
        final circle = frame.kind == CoverFrameKind.circle;
        body = Row(children: [
          SizedBox(
            width: frame.width,
            height: frame.height,
            child: circle
                ? ClipOval(child: pic)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10), child: pic),
          ),
          const SizedBox(width: 12),
          if (name.isNotEmpty)
            Expanded(
              child: Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
        ]);
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(frame.label,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          const SizedBox(height: 4),
          body,
        ],
      ),
    );
  }
}

/// Rule-of-thirds guide over the positioning frame.
class _ThirdsGrid extends StatelessWidget {
  const _ThirdsGrid();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ThirdsPainter());
}

class _ThirdsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
